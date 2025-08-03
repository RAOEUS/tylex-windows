window.addEventListener('pywebviewready', () => {
    const snippetListBody = document.getElementById('snippet-list-body');
    const snippetForm = document.getElementById('snippet-form');
    const abbvInput = document.getElementById('abbv-input');
    const valueInput = document.getElementById('value-input');

    // --- Functions ---
    async function loadSnippets() {
        const snippets = await window.pywebview.api.get_all_snippets();
        snippetListBody.innerHTML = '';
        snippets.forEach(snippet => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td class="abbv-col">${snippet.abbv}</td>
                <td class="value-col">${snippet.value}</td>
                <td class="actions-col">
                    <button class="btn btn-delete" data-abbv="${snippet.abbv}">Delete</button>
                </td>
            `;
            snippetListBody.appendChild(tr);
        });
    }

    async function handleFormSubmit(e) {
        e.preventDefault();
        const data = {
            abbv: abbvInput.value,
            value: valueInput.value
        };
        const result = await window.pywebview.api.add_or_update_snippet(data);
        if (result.status === 'success') {
            snippetForm.reset();
            loadSnippets(); // Refresh the list
        }
    }
    
    async function handleDeleteClick(e) {
        if (e.target.classList.contains('btn-delete')) {
            const abbv = e.target.dataset.abbv;
            if (confirm(`Are you sure you want to delete the snippet for '${abbv}'?`)) {
                await window.pywebview.api.delete_snippet(abbv);
                loadSnippets(); // Refresh the list
            }
        }
    }
    
    async function applyTranslations() {
        const t = await window.pywebview.api.get_translations();
        for (const key in t) {
            const element = document.getElementById(key);
            if (element) {
                element.textContent = t[key];
            }
        }
    }

    // --- Event Listeners ---
    snippetForm.addEventListener('submit', handleFormSubmit);
    snippetListBody.addEventListener('click', handleDeleteClick);

    // Initial Load
    applyTranslations();
    loadSnippets();
});
