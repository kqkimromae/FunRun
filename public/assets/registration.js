(() => {
  const form = document.querySelector("#registration-form");
  if (!form) return;
  const panels = Array.from(form.querySelectorAll("[data-panel]"));
  const indicators = Array.from(document.querySelectorAll("[data-indicator]"));
  const terms = document.querySelector("#accept-terms");  const termsBox = document.querySelector("#registration-terms");
  if (terms && termsBox) {
    terms.disabled = true;
    termsBox.addEventListener("scroll", () => {
      if (termsBox.scrollTop + termsBox.clientHeight >= termsBox.scrollHeight - 8) terms.disabled = false;
    });
  }
  function showStep(step) {
    panels.forEach((panel) => {
      const active = Number(panel.dataset.panel) === step;
      panel.classList.toggle("active", active);
      panel.querySelectorAll("input,select,textarea,button").forEach((control) => {
        if (control.matches("[data-next-step],[data-prev-step]")) return;
        if (active) { if (control.dataset.stepDisabled) { control.disabled=false; delete control.dataset.stepDisabled; } }
        else if (!control.disabled) { if (control.name === "accept_terms") control.required=false; control.disabled=true; control.dataset.stepDisabled="1"; }
      });
    });
    indicators.forEach((item) => { const n=Number(item.dataset.indicator); item.classList.toggle("active",n===step); item.classList.toggle("complete",n<step); });
    form.dataset.currentStep=String(step);
    if (terms) terms.required=step===1;
    const shell=document.querySelector(".registration-shell");
    if(shell) window.scrollTo({top:shell.offsetTop-12,behavior:"smooth"});
  }
  function validatePanel(step) {
    const panel=form.querySelector("[data-panel=\"" + step + "\"]");
    for(const control of panel.querySelectorAll("input,select,textarea")) {
      if(control.disabled||control.type==="file"||(control.type==="checkbox"&&!control.required)) continue;
      if(!control.checkValidity()){control.reportValidity();return false;}
    }
    return true;
  }
  form.querySelectorAll("[data-next-step]").forEach((button)=>button.addEventListener("click",()=>{
    const current=Number(form.dataset.currentStep||1);
    if(current===1&&terms&&!terms.checked){alert("กรุณาอ่านและยอมรับกติกาการสมัครก่อน");terms.focus();return;}
    if(current===2&&!validatePanel(2))return;
    showStep(Number(button.dataset.nextStep));
  }));
  form.querySelectorAll("[data-prev-step]").forEach((button)=>button.addEventListener("click",()=>showStep(Number(button.dataset.prevStep))));
  form.addEventListener("submit",()=>form.querySelectorAll("[data-step-disabled]").forEach((control)=>{control.disabled=false;delete control.dataset.stepDisabled;}));
  showStep(1);
})();
