window.SITE = {
  name: "{{NAME}}",

  // Digits only with country code, e.g. "5511999998888". Empty → floating button removed.
  whatsapp: { number: "{{WHATSAPP_DIGITS}}", message: "{{WHATSAPP_MESSAGE}}" },

  // Priority: endpoint (own backend / WP REST) > web3formsKey > email (FormSubmit). All empty → form hidden.
  // A <form action="..."> in index.html bypasses all of this and submits natively.
  contact: {
    endpoint: "",
    web3formsKey: "",
    email: "",
    subject: "Novo contato pelo site {{NAME}}",
  },

  messages: {
    fix: "Confira os campos destacados.",
    sending: "Enviando…",
    sent: "Recebemos seu contato. Em breve falamos com você.",
    failed: "Não foi possível enviar agora. Chame no WhatsApp.",
  },

  // Paste the line printed by scripts/slice_frames.sh. For two scenes use an array (references/motion.md).
  frames: { total: 160, desktop: "assets/frames/desktop/f_{n}.webp", mobile: "assets/frames/mobile/f_{n}.webp" },
};
