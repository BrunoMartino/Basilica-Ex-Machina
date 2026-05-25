# Examples (guides only)

Adapt block syntax and language to each repository (JavaScript/TypeScript JSDoc, TSDoc, Go doc blocks, etc.). Keep the **same sections**: summary, flow or behavior, deps/params, where/when used.

---

## Pattern: orchestration controller (Portuguese corpus example)

Illustrative JSDoc-style block for a complex coordinator:

```ts
/**
 * ImportarController
 *
 * Orquestra o processamento em lote da importacao via planilha:
 *  - Transforma `LinhaExcel` em `CreateFechamentoInput`.
 *  - Delega o trabalho pesado ao `importDelegate.createFechamentosBatch`
 *    (unica roundtrip de lookup + insert em lote + update via VALUES).
 *  - Converte o resultado do lote no formato publico esperado pela rota
 *    (contagem + magicLinks + erros), mantendo a numeracao das linhas do
 *    Excel (cabecalho = linha 1, primeira linha de dados = linha 2).
 *
 * Aceita um callback opcional `p_on_progress(processed, total)` que e
 * repassado ao delegate, permitindo que a rota exponha progresso real de
 * processamento ao cliente via stream.
 */
```

---

## Pattern: auth helper — params + call sites

```ts
/**
 * Verifica se o usuario da sessao atual e admin no banco de dados.
 *
 * Esta funcao roda apenas no server (Server Components, Route Handlers,
 * Server Actions) e encapsula toda a logica de autenticacao +
 * autorizacao para rotas administrativas.
 *
 * Params Usado:
 * - id, name, value e etc..
 *
 * Use este helper em:
 * - Layouts que protegem sub-rotas /admin/*
 * - Route Handlers em /api/importar/* e em endpoints administrativos
 *   de fechamento (ex.: create, delete, update-jwt, list, download-nf,
 *   update-payment-info, upload-relatorio).
 */
```

Replace placeholder param bullets with **real** names and types from the function signature.

---

## Good: ZIP entry point documented + shared helper

High-level archive behavior stated up front:

```ts
/**
 * Creates a ZIP archive (compression method 0 = stored) from named file buffers.
 * Dependency-free; suitable for bundling PDFs server-side.
 */

function buildCrc32Table(): Uint32Array {
  const l_table = new Uint32Array(256);
  for (let l_n = 0; l_n < 256; l_n++) {
    let l_c = l_n;
    for (let l_k = 0; l_k < 8; l_k++) {
      l_c = l_c & 1 ? 0xedb88320 ^ (l_c >>> 1) : l_c >>> 1;
    }
    l_table[l_n] = l_c >>> 0;
  }
  return l_table;
}

const CRC32_TABLE = buildCrc32Table();

export function computeCrc32ForBuffer(p_buffer: Buffer): number {
  let l_crc = 0xffffffff;
  for (let l_i = 0; l_i < p_buffer.length; l_i++) {
    l_crc = CRC32_TABLE[(l_crc ^ p_buffer[l_i]!) & 0xff]! ^ (l_crc >>> 8);
  }
  return (l_crc ^ 0xffffffff) >>> 0;
}

export type ZipEntryInput = {
  name: string;
  data: Buffer;
};
```

Cross-cutting URL helper with **who shares it** and **why**:

```ts
/**
 * Helper compartilhado entre `FechamentoDelegate` e `ImportDelegate` para
 * resolver a base URL publica e montar o magic link canonico de acesso ao
 * fechamento (`/fechamento/{hash}`), evitando divergencia entre os dois
 * fluxos (criacao individual x importacao em lote).
 */

const DEFAULT_PUBLIC_BASE_URL = 'http://localhost:3000';

export function resolvePublicBaseUrl(): string {
  const l_baseUrl =
    process.env.NEXT_PUBLIC_BASE_URL ?? DEFAULT_PUBLIC_BASE_URL;
  return l_baseUrl.replace(/\/$/, '');
}

export function buildMagicLinkForFechamento(p_fechamentoId: number): string {
  const l_hash = buildFechamentoHash(p_fechamentoId);
  return `${resolvePublicBaseUrl()}/fechamento/${l_hash}`;
}
```

---

## Bad: complex ZIP builder with no top-level explanation

This function implements local headers, central directory, and EOCD offsets. Without a block comment, readers (and agents) must reverse-engineer the ZIP layout from magic numbers alone.

```ts
export function buildZipArchiveFromStoredEntries(
  p_entries: ZipEntryInput[],
): Buffer {
  const l_parts: Buffer[] = [];
  let l_offset = 0;
  const l_centralParts: Buffer[] = [];

  for (const l_entry of p_entries) {
    const l_nameBuf = Buffer.from(l_entry.name, 'utf8');
    const l_data = l_entry.data;
    const l_crc = computeCrc32ForBuffer(l_data);
    const l_size = l_data.length;
    const l_localHeader = Buffer.alloc(30);
    l_localHeader.writeUInt32LE(0x04034b50, 0);
    l_localHeader.writeUInt16LE(20, 4);
    l_localHeader.writeUInt16LE(0, 6);
    l_localHeader.writeUInt16LE(0, 8);
    l_localHeader.writeUInt16LE(0, 10);
    l_localHeader.writeUInt16LE(0, 12);
    l_localHeader.writeUInt32LE(l_crc, 14);
    l_localHeader.writeUInt32LE(l_size, 18);
    l_localHeader.writeUInt32LE(l_size, 22);
    l_localHeader.writeUInt16LE(l_nameBuf.length, 26);
    l_localHeader.writeUInt16LE(0, 28);
    l_parts.push(l_localHeader, l_nameBuf, l_data);

    const l_central = Buffer.alloc(46);
    l_central.writeUInt32LE(0x02014b50, 0);
    l_central.writeUInt16LE(20, 4);
    l_central.writeUInt16LE(20, 6);
    l_central.writeUInt16LE(0, 8);
    l_central.writeUInt16LE(0, 10);
    l_central.writeUInt16LE(0, 12);
    l_central.writeUInt16LE(0, 14);
    l_central.writeUInt32LE(l_crc, 16);
    l_central.writeUInt32LE(l_size, 20);
    l_central.writeUInt32LE(l_size, 24);
    l_central.writeUInt16LE(l_nameBuf.length, 28);
    l_central.writeUInt16LE(0, 30);
    l_central.writeUInt16LE(0, 32);
    l_central.writeUInt16LE(0, 34);
    l_central.writeUInt16LE(0, 36);
    l_central.writeUInt32LE(0, 38);
    l_central.writeUInt32LE(l_offset, 42);
    l_centralParts.push(l_central, l_nameBuf);

    l_offset += 30 + l_nameBuf.length + l_size;
  }

  const l_centralSize = Buffer.concat(l_centralParts).length;
  const l_centralOffset = l_offset;
  l_parts.push(...l_centralParts);

  const l_eocd = Buffer.alloc(22);
  l_eocd.writeUInt32LE(0x06054b50, 0);
  l_eocd.writeUInt16LE(0, 4);
  l_eocd.writeUInt16LE(0, 6);
  l_eocd.writeUInt16LE(p_entries.length, 8);
  l_eocd.writeUInt16LE(p_entries.length, 10);
  l_eocd.writeUInt32LE(l_centralSize, 12);
  l_eocd.writeUInt32LE(l_centralOffset, 16);
  l_eocd.writeUInt16LE(0, 20);
  l_parts.push(l_eocd);

  return Buffer.concat(l_parts);
}
```

**Improvement**: add a JSDoc (or equivalent) summarizing stored-only entries, CRC32 usage, ordering of segments, and `p_entries` expectations—similar in density to the “Good” ZIP introduction above.
