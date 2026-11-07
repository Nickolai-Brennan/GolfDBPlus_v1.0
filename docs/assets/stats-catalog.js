/* Works on initial loads and Material's instant navigation. */
function initializeStatsCatalog() {
  const root = document.querySelector('[data-stats-catalog]');
  if (!root || root.dataset.initialized) return;
  root.dataset.initialized = 'true';
  const search = root.querySelector('[data-search]');
  const category = root.querySelector('[data-category]');
  const subcategory = root.querySelector('[data-subcategory]');
  const rows = Array.from(root.querySelectorAll('tbody tr'));
  const entries = rows.map(row => ({
    row,
    text: `${row.cells[0].querySelector('code').textContent} ${row.cells[1].textContent}`.toLowerCase()
  }));
  function options(select, values, label) {
    select.replaceChildren(new Option(label, ''));
    [...new Set(values)].sort().forEach(value => select.add(new Option(value, value)));
  }
  options(category, rows.map(row => row.dataset.category), 'All categories');
  function updateSubcategories() {
    const previous = subcategory.value;
    options(subcategory, rows.filter(row => !category.value || row.dataset.category === category.value)
      .map(row => row.dataset.subcategory), 'All subcategories');
    if (Array.from(subcategory.options).some(option => option.value === previous)) subcategory.value = previous;
  }
  function filter() {
    const terms = search.value.trim().toLowerCase().split(/\s+/).filter(Boolean);
    let count = 0;
    entries.forEach(({row, text}) => {
      const matches = terms.every(term => text.includes(term)) &&
        (!category.value || row.dataset.category === category.value) &&
        (!subcategory.value || row.dataset.subcategory === subcategory.value);
      row.hidden = !matches;
      if (matches) count++;
    });
    root.querySelector('[data-count]').textContent = `${count} of ${rows.length} ${root.dataset.itemLabel || 'statistics'}`;
    root.querySelector('[data-empty]').hidden = count > 0;
  }
  updateSubcategories();
  search.addEventListener('input', filter);
  category.addEventListener('change', () => { updateSubcategories(); filter(); });
  subcategory.addEventListener('change', filter);
  root.querySelector('[data-reset]').addEventListener('click', () => {
    search.value = ''; category.value = ''; subcategory.value = '';
    updateSubcategories(); filter(); search.focus();
  });
  root.querySelectorAll('[data-copy]').forEach(button => {
    button.hidden = false;
    button.addEventListener('click', async () => {
      const status = root.querySelector('[data-copy-status]');
      try {
        await navigator.clipboard.writeText(button.dataset.copy);
        status.textContent = `Copied ${button.dataset.copy}`;
      } catch {
        status.textContent = `Copy unavailable. Select and copy ID ${button.dataset.copy} manually.`;
      }
    });
  });
  root.querySelector('.stats-controls').hidden = false;
  filter();
}
if (typeof document$ !== 'undefined') document$.subscribe(initializeStatsCatalog);
else if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', initializeStatsCatalog);
else initializeStatsCatalog();
