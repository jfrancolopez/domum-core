(() => {
  const timeFormatter = new Intl.DateTimeFormat(undefined, {
    hour: "numeric",
    minute: "2-digit",
  });
  const dateFormatter = new Intl.DateTimeFormat(undefined, {
    month: "long",
    day: "numeric",
    year: "numeric",
  });

  function addHeaderClasses() {
    const widgetsWrap = document.querySelector("#widgets-wrap");
    if (!widgetsWrap) return false;

    widgetsWrap.classList.add("domum-header-grid");
    widgetsWrap.querySelector(".information-widget-logo")?.classList.add("domum-branding");

    const resourceWidgets = [...widgetsWrap.querySelectorAll(".widget-container")]
      .filter((widget) => widget.querySelector(".information-widget-resource"));

    for (const widget of resourceWidgets) {
      const text = widget.textContent || "";
      if (text.includes("Homepage Runtime")) widget.classList.add("domum-primary-metrics");
      if (text.includes("Root NVMe")) widget.classList.add("domum-disk-metric");
      if (text.includes("Uptime")) widget.classList.add("domum-uptime-metric");
    }

    const primaryMetrics = widgetsWrap.querySelector(".domum-primary-metrics");
    const metricPills = primaryMetrics
      ? [...primaryMetrics.querySelectorAll(".information-widget-resource")]
      : [];
    metricPills[0]?.classList.add("domum-metric-cpu");
    metricPills[1]?.classList.add("domum-metric-ram");
    metricPills[2]?.classList.add("domum-metric-temp");
    widgetsWrap.querySelector(".domum-disk-metric .information-widget-resource")?.classList.add("domum-metric-disk");
    widgetsWrap.querySelector(".domum-uptime-metric .information-widget-resource")?.classList.add("domum-metric-uptime");

    const branding = widgetsWrap.querySelector(".domum-branding");
    let metricsRow = widgetsWrap.querySelector(".domum-metrics-row");
    if (!metricsRow) {
      metricsRow = document.createElement("div");
      metricsRow.className = "domum-metrics-row";
      branding?.after(metricsRow);
    }

    for (const widget of resourceWidgets) {
      if (widget.parentElement !== metricsRow) metricsRow.append(widget);
    }

    const utilityRow = widgetsWrap.querySelector(".information-widget-datetime")?.parentElement;
    utilityRow?.classList.add("domum-utility-row");
    widgetsWrap.querySelector(".information-widget-datetime")?.classList.add("domum-datetime");
    widgetsWrap.querySelector(".information-widget-search")?.classList.add("domum-search");
    widgetsWrap.querySelector(".information-widget-openmeteo")?.classList.add("domum-weather");

    return true;
  }

  function addSystemLayoutClasses() {
    const layoutGroups = document.querySelector("#layout-groups");
    if (!layoutGroups) return false;

    const groupClasses = {
      "Core Status": "domum-group-core-status",
      Servers: "domum-group-servers",
      Calendar: "domum-group-calendar",
      Network: "domum-group-network",
      "Home Automation": "domum-group-home-automation",
    };

    const groups = [...layoutGroups.querySelectorAll(".services-group")];
    let systemGroupCount = 0;

    for (const group of groups) {
      const title = group.querySelector("h2.service-group-name")?.textContent?.trim();
      const className = groupClasses[title];
      if (!className) continue;

      group.classList.add(className);
      systemGroupCount += 1;
    }

    layoutGroups.classList.toggle("domum-system-layout", systemGroupCount === Object.keys(groupClasses).length);
    return systemGroupCount > 0;
  }

  function updateDateTime() {
    const widget = document.querySelector(
      "#information-widgets .information-widget-datetime span:not(.domum-time):not(.domum-date)",
    );
    if (!widget) return;

    const now = new Date();
    const time = timeFormatter.format(now);
    const date = dateFormatter.format(now);

    if (widget.dataset.domumTime === time && widget.dataset.domumDate === date && !widget.innerText.includes(" at ")) {
      return;
    }

    widget.dataset.domumTime = time;
    widget.dataset.domumDate = date;
    widget.innerHTML = `<span class="domum-time">${time}</span> <span class="domum-date">${date}</span>`;
  }

  addHeaderClasses();
  addSystemLayoutClasses();
  updateDateTime();
  setInterval(updateDateTime, 1000);
  new MutationObserver(() => {
    addHeaderClasses();
    addSystemLayoutClasses();
    updateDateTime();
  }).observe(document.getElementById("__next") || document.documentElement, {
    childList: true,
    characterData: true,
    subtree: true,
  });
})();
