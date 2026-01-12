// Browser Extension Popup Script
document.addEventListener('DOMContentLoaded', async () => {
  const urlInput = document.getElementById('url');
  const titleInput = document.getElementById('title');
  const notesInput = document.getElementById('notes');
  const saveButton = document.getElementById('saveButton');
  const statusDiv = document.getElementById('status');
  const openWebAppLink = document.getElementById('openWebApp');
  
  // Get current tab information
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    
    if (tab) {
      urlInput.value = tab.url;
      titleInput.value = tab.title || '';
      
      // Extract domain for web app link
      const url = new URL(tab.url);
      const webAppUrl = `https://your-web-app-domain.com`; // Update with your web app URL
      openWebAppLink.href = webAppUrl;
    }
  } catch (error) {
    console.error('Failed to get tab info:', error);
    showStatus('Failed to get page information', 'error');
  }
  
  // Handle form submission
  document.getElementById('bookmarkForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const bookmarkData = {
      url: urlInput.value.trim(),
      title: titleInput.value.trim() || null,
      notes: notesInput.value.trim() || null,
      createdAt: new Date().toISOString(),
      modifiedAt: new Date().toISOString()
    };
    
    if (!bookmarkData.url) {
      showStatus('URL is required', 'error');
      return;
    }
    
    try {
      saveButton.disabled = true;
      showStatus('Saving bookmark...', 'loading');
      
      // Save to local storage (will be synced by web app)
      await saveBookmarkLocally(bookmarkData);
      
      // Try to communicate with web app if open
      await notifyWebApp(bookmarkData);
      
      showStatus('Bookmark saved successfully!', 'success');
      
      // Close popup after delay
      setTimeout(() => {
        window.close();
      }, 1500);
      
    } catch (error) {
      console.error('Failed to save bookmark:', error);
      showStatus('Failed to save bookmark', 'error');
      saveButton.disabled = false;
    }
  });
  
  // Open web app link
  openWebAppLink.addEventListener('click', (e) => {
    e.preventDefault();
    chrome.tabs.create({ url: openWebAppLink.href });
  });
});

async function saveBookmarkLocally(bookmarkData) {
  // Get existing bookmarks
  const result = await chrome.storage.local.get(['bookmarks']);
  const bookmarks = result.bookmarks || [];
  
  // Add new bookmark with unique ID
  const newBookmark = {
    ...bookmarkData,
    id: generateId(),
    synced: false
  };
  
  bookmarks.unshift(newBookmark);
  
  // Save back to storage
  await chrome.storage.local.set({ bookmarks });
  
  return newBookmark;
}

async function notifyWebApp(bookmarkData) {
  // Try to find and communicate with web app tab
  try {
    const tabs = await chrome.tabs.query({});
    const webAppTabs = tabs.filter(tab => 
      tab.url && tab.url.includes('your-web-app-domain.com') // Update with your domain
    );
    
    for (const tab of webAppTabs) {
      try {
        await chrome.tabs.sendMessage(tab.id, {
          type: 'NEW_BOOKMARK',
          data: bookmarkData
        });
      } catch (error) {
        // Tab might not have content script, ignore
      }
    }
  } catch (error) {
    // Web app not open, that's fine
  }
}

function showStatus(message, type) {
  const statusDiv = document.getElementById('status');
  statusDiv.textContent = message;
  statusDiv.className = `status ${type}`;
  statusDiv.style.display = 'block';
  
  if (type === 'success' || type === 'error') {
    setTimeout(() => {
      statusDiv.style.display = 'none';
    }, 3000);
  }
}

function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}
