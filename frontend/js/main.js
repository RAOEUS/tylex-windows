window.addEventListener('pywebviewready', () => {
	const searchBox = document.getElementById('search-box');
	const resultsList = document.getElementById('results-list');
	let selectedIndex = 0;

	async function search() {
		const query = searchBox.value;
		const results = await window.pywebview.api.search_snippets(query);
		renderResults(results);
	}

	function renderResults(results) {
		resultsList.innerHTML = '';
		if (results.length === 0) { return; }
		results.forEach((item, index) => {
			const li = document.createElement('li');
			li.dataset.abbv = item.abbv;
			li.innerHTML = `
      <span class="abbv">${item.abbv}</span>
      <span class="value">${item.value}</span>
      <span class="usage-count">${item.usage_count}</span>
    `;
			li.addEventListener('click', () => { pasteSnippet(item.abbv); });
			resultsList.appendChild(li);
		});
		selectedIndex = 0;
		updateSelection();
	}


	function updateSelection() {
		const items = resultsList.getElementsByTagName('li');
		for (let i = 0; i < items.length; i++) {
			items[i].classList.remove('selected');
		}
		if (items.length > 0) {
			items[selectedIndex].classList.add('selected');
			items[selectedIndex].scrollIntoView({ block: 'nearest' });
		}
	}

	function pasteSnippet(abbv) {
		window.pywebview.api.paste_text(abbv);
	}

	async function applyTranslations() {
		const t = await window.pywebview.api.get_translations();
		document.getElementById('app_title').textContent = t['app_title'] || 'Tylex';
		searchBox.placeholder = t['search_placeholder'] || 'Search snippets...';
	}

	searchBox.addEventListener('input', search);

	document.addEventListener('keydown', (e) => {
		const items = resultsList.getElementsByTagName('li');
		if (e.key === 'Escape') {
			window.pywebview.api.close_search_window();
		} else if (e.key === 'ArrowDown') {
			e.preventDefault();
			if (selectedIndex < items.length - 1) { selectedIndex++; updateSelection(); }
		} else if (e.key === 'ArrowUp') {
			e.preventDefault();
			if (selectedIndex > 0) { selectedIndex--; updateSelection(); }
		} else if (e.key === 'Enter') {
			e.preventDefault();
			if (items.length > 0 && items[selectedIndex]) {
				const abbv = items[selectedIndex].dataset.abbv;
				pasteSnippet(abbv);
				// clear out the search field and results
				searchBox.value = '';
				resultsList.innerHTML = '';
				searchBox.value = '';
				search();
			}
		}
	});

	applyTranslations();
	search();
});
