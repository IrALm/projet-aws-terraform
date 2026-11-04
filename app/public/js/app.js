// Comportements d'interface (navigateur uniquement) : thème clair/sombre, menu actif,
// filtre du tableau, boîte de confirmation. Aucune dépendance.
(function () {
  "use strict";

  var root = document.documentElement;

  // ---------- Thème clair / sombre (mémorisé dans le navigateur) ----------
  function currentTheme() {
    return root.getAttribute("data-theme") === "dark" ? "dark" : "light";
  }
  function updateToggleLabels() {
    var label = currentTheme() === "dark" ? "Switch to light theme" : "Switch to dark theme";
    document.querySelectorAll("[data-theme-toggle]").forEach(function (btn) {
      btn.setAttribute("aria-label", label);
      btn.setAttribute("title", label);
    });
  }
  document.querySelectorAll("[data-theme-toggle]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var next = currentTheme() === "dark" ? "light" : "dark";
      root.setAttribute("data-theme", next);
      try { localStorage.setItem("theme", next); } catch (e) { /* stockage indisponible */ }
      updateToggleLabels();
    });
  });
  updateToggleLabels();

  // ---------- Entrée de menu active ----------
  var path = window.location.pathname.replace(/\/+$/, "") || "/";
  var section = path === "/" ? "home"
    : path.indexOf("/supplier-add") === 0 ? "add"
    : (path.indexOf("/students") === 0 || path.indexOf("/supplier-update") === 0) ? "students"
    : "";
  document.querySelectorAll("[data-nav]").forEach(function (link) {
    if (link.getAttribute("data-nav") === section) {
      link.classList.add("is-active");
      link.setAttribute("aria-current", "page");
    }
  });
  document.querySelectorAll("[data-crumb]").forEach(function (el) {
    var names = { home: "Dashboard", students: "Students", add: "New student" };
    if (names[section]) el.textContent = names[section];
  });

  // ---------- Filtre instantané du tableau + compteur ----------
  document.querySelectorAll("[data-table-filter]").forEach(function (input) {
    var table = document.getElementById(input.getAttribute("data-table-filter"));
    if (!table) return;
    var rows = Array.prototype.slice.call(table.querySelectorAll("tbody tr:not(.empty-row)"));
    var counter = document.querySelector('[data-row-count="' + table.id + '"]');

    function refresh() {
      var query = input.value.trim().toLowerCase();
      var visible = 0;
      rows.forEach(function (row) {
        var match = !query || row.textContent.toLowerCase().indexOf(query) !== -1;
        row.hidden = !match;
        if (match) visible++;
      });
      if (counter) {
        counter.textContent = query
          ? visible + " of " + rows.length + " records"
          : rows.length + (rows.length === 1 ? " record" : " records");
      }
    }
    input.addEventListener("input", refresh);
    refresh();
  });

  // ---------- Boîte de confirmation (élément <dialog> natif) ----------
  document.querySelectorAll("[data-dialog-open]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var dialog = document.getElementById(btn.getAttribute("data-dialog-open"));
      if (dialog && typeof dialog.showModal === "function") dialog.showModal();
    });
  });
  document.querySelectorAll("[data-dialog-close]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var dialog = btn.closest("dialog");
      if (dialog) dialog.close();
    });
  });
})();
