/* amaterasu-sugoi · hero image sequence + section motion. Needs window.gsap + window.ScrollTrigger. */
(() => {
  const S = window.SITE || {};
  const root = document.querySelector("body.sugoi") || document.body;
  if (!window.gsap || !window.ScrollTrigger) return;
  gsap.registerPlugin(ScrollTrigger);
  const mm = gsap.matchMedia();
  const MOTION = "(prefers-reduced-motion: no-preference)";

  /* ── Hero: canvas sequence scrubbed by scroll ─────────────────────────── */
  const cine = root.querySelector(".cine");
  const canvas = cine && cine.querySelector(".cine-canvas");
  const seq = Array.isArray(S.frames) ? S.frames[0] : S.frames;
  if (cine && canvas && seq && seq.total) {
    const ctx = canvas.getContext("2d");
    const total = seq.total;
    const pattern = matchMedia("(max-width: 760px)").matches && seq.mobile ? seq.mobile : seq.desktop;
    const src = (i) => pattern.replace("{n}", String(i + 1).padStart(4, "0"));
    const imgs = new Array(total);
    const pos = { i: 0 };
    let drawn = -1;

    const ready = (i) => imgs[i] && imgs[i].complete && imgs[i].naturalWidth;
    const nearest = (i) => {
      for (let d = 0; d < total; d++) { if (ready(i - d)) return i - d; if (ready(i + d)) return i + d; }
      return -1;
    };
    const draw = (i, force) => {
      const j = nearest(i);
      if (j < 0 || (j === drawn && !force)) return;
      const im = imgs[j], cw = canvas.width, ch = canvas.height;
      const s = Math.max(cw / im.naturalWidth, ch / im.naturalHeight); // cover
      const w = im.naturalWidth * s, h = im.naturalHeight * s;
      ctx.drawImage(im, (cw - w) / 2, (ch - h) / 2, w, h);
      drawn = j;
    };
    const load = (i) => {
      if (imgs[i]) return imgs[i];
      const im = new Image();
      im.decoding = "async";
      im.src = src(i);
      im.onload = () => { if (drawn === -1 || Math.round(pos.i) === i) draw(i, true); };
      return (imgs[i] = im);
    };
    const fit = () => {
      const dpr = Math.min(devicePixelRatio || 1, 2);
      canvas.width = Math.round(canvas.clientWidth * dpr);
      canvas.height = Math.round(canvas.clientHeight * dpr);
      drawn = -1;
      draw(Math.round(pos.i), true);
    };
    // Passes 8 → 4 → 2 → 1 so the whole timeline is coarsely scrubbable early.
    const preload = () => {
      const q = [];
      for (const step of [8, 4, 2, 1]) for (let i = 0; i < total; i += step) if (!q.includes(i)) q.push(i);
      let k = 0;
      const batch = () => { for (let n = 0; n < 6 && k < q.length; n++) load(q[k++]); if (k < q.length) setTimeout(batch, 40); };
      batch();
    };

    load(0);
    fit();
    addEventListener("resize", fit);

    mm.add(MOTION, () => {
      preload();
      // Timeline duration = 1 → tween positions are scroll-progress fractions.
      const tl = gsap.timeline({ scrollTrigger: { trigger: cine, start: "top top", end: "bottom bottom", scrub: 0.6 } });
      tl.to(pos, { i: total - 1, ease: "none", duration: 1, onUpdate: () => draw(Math.round(pos.i)) }, 0);
      cine.querySelectorAll(".moment").forEach((m) => {
        const from = +(m.dataset.from || 0), to = +(m.dataset.to || 1);
        tl.fromTo(m, { autoAlpha: 0, y: 24, filter: "blur(6px)" },
          { autoAlpha: 1, y: 0, filter: "blur(0px)", duration: 0.07, ease: "power2.out" }, from);
        if (to < 1) tl.to(m, { autoAlpha: 0, y: -16, duration: 0.05, ease: "power2.in" }, to - 0.05);
      });
      const hint = cine.querySelector(".cine-hint");
      if (hint) tl.to(hint, { autoAlpha: 0, duration: 0.02 }, 0.01);
    });
    mm.add("(prefers-reduced-motion: reduce)", () => { pos.i = 0; draw(0, true); });
  }

  /* ── Section art parallax + reveal ────────────────────────────────────── */
  mm.add(MOTION, () => {
    gsap.utils.toArray(".art", root).forEach((a) =>
      gsap.fromTo(a, { yPercent: 5 }, { yPercent: -5, ease: "none",
        scrollTrigger: { trigger: a.parentElement, start: "top bottom", end: "bottom top", scrub: true } }));
    gsap.set(".reveal", { autoAlpha: 0, y: 40 });
    ScrollTrigger.batch(".reveal", { start: "top 85%", once: true,
      onEnter: (els) => gsap.to(els, { autoAlpha: 1, y: 0, duration: 1, ease: "power3.out", stagger: 0.12 }) });
  });

  /* ── Header, floating WhatsApp, year ──────────────────────────────────── */
  const header = root.querySelector(".header");
  const whats = root.querySelector(".whats");
  const form = root.querySelector(".form");
  let formVisible = false; // hide the floating button while the form is on screen
  const onScroll = () => {
    header && header.classList.toggle("scrolled", scrollY > 40);
    whats && whats.classList.toggle("visible", scrollY > innerHeight * 0.6 && !formVisible);
  };
  if (form) ScrollTrigger.create({ trigger: form, start: "top bottom", end: "bottom top",
    onToggle: (self) => { formVisible = self.isActive; onScroll(); } });
  addEventListener("scroll", onScroll, { passive: true });
  onScroll();
  root.querySelectorAll("[data-year]").forEach((el) => (el.textContent = new Date().getFullYear()));

  if (whats) {
    const W = S.whatsapp || {};
    const num = String(W.number || "").replace(/\D/g, "");
    if (num) whats.href = `https://wa.me/${num}?text=${encodeURIComponent(W.message || "")}`;
    else whats.remove();
  }

  /* ── Contact form: native action > endpoint > Web3Forms > FormSubmit ─── */
  if (form && !form.hasAttribute("action")) {
    const C = S.contact || {}, M = S.messages || {};
    const status = form.querySelector(".form-status");
    const btn = form.querySelector("button[type=submit]");
    const say = (t, k) => { if (status) { status.textContent = t; status.className = `form-status span-all ${k || ""}`; } };
    const subject = C.subject || `New contact · ${S.name || "site"}`;
    const target = C.endpoint ? [C.endpoint, (d) => ({ subject, ...d })]
      : C.web3formsKey ? ["https://api.web3forms.com/submit", (d) => ({ access_key: C.web3formsKey, subject, from_name: S.name, ...d })]
      : C.email ? [`https://formsubmit.co/ajax/${encodeURIComponent(C.email)}`, (d) => ({ _subject: subject, _template: "table", _captcha: "false", ...d })]
      : null;

    if (!target) form.hidden = true;
    else form.addEventListener("submit", async (ev) => {
      ev.preventDefault();
      if (form.elements._honey && form.elements._honey.value) return;
      let ok = true;
      form.querySelectorAll("[required]").forEach((c) => {
        const v = c.type === "email" ? /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(c.value) : c.value.trim().length > 1;
        c.closest(".field").classList.toggle("error", !v);
        if (!v) ok = false;
      });
      if (!ok) return say(M.fix || "Check the highlighted fields.", "fail");
      const data = Object.fromEntries(new FormData(form));
      delete data._honey;
      btn.disabled = true;
      say(M.sending || "Sending…");
      try {
        const r = await fetch(target[0], { method: "POST",
          headers: { "Content-Type": "application/json", Accept: "application/json" }, body: JSON.stringify(target[1](data)) });
        const j = await r.json().catch(() => ({}));
        if (!r.ok || j.success === false || j.success === "false") throw new Error(j.message || r.status);
        form.reset();
        say(M.sent || "Message received.", "ok");
      } catch (e) {
        console.warn("form:", e);
        say(M.failed || "Could not send right now.", "fail");
      } finally {
        btn.disabled = false;
      }
    });
  }
})();
