// Background Service Worker
chrome.runtime.onInstalled.addListener(() => {
  console.log('URL Bookmarks extension installed');
});

// Handle messages from content scripts or popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'SAVE_BOOKMARK') {
    handleSaveBookmark(message.data)
      .then(result => sendResponse({ success: true, data: result }))
      .catch(error => sendResponse({ success: false, error: error.message }));
    return true; // Keep message channel open for async response
  }
});

// Context menu for right-click save
chrome.contextMenus.create({
  id: 'saveToBookmarks',
  title: 'Save to URL Bookmarks',
  contexts: ['page', 'link']
});

chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  if (info.menuItemId === 'saveToBookmarks') {
    const url = info.linkUrl || tab.url;
    const title = tab.title || '';
    
    const bookmarkData = {
      url,
      title,
      notes: null,
      createdAt: new Date().toISOString(),
      modifiedAt: new Date().toISOString()
    };
    
    try {
      await handleSaveBookmark(bookmarkData);
      
      // Show notification
      chrome.notifications.create({
        type: 'basic',
        iconUrl: 'icons/icon48.png',
        title: 'URL Bookmarks',
        message: 'Bookmark saved successfully!'
      });
    } catch (error) {
      console.error('Failed to save bookmark:', error);
      
      chrome.notifications.create({
        type: 'basic',
        iconUrl: 'icons/icon48.png',
        title: 'URL Bookmarks',
        message: 'Failed to save bookmark'
      });
    }
  }
});

async function handleSaveBookmark(bookmarkData) {
  // Save to local storage
  const result = await chrome.storage.local.get(['bookmarks']);
  const bookmarks = result.bookmarks || [];
  
  const newBookmark = {
    ...bookmarkData,
    id: generateId(),
    synced: false
  };
  
  bookmarks.unshift(newBookmark);
  await chrome.storage.local.set({ bookmarks });
  
  // Try to sync with web app
  await syncWithWebApp();
  
  return newBookmark;
}

async function syncWithWebApp() {
  // This would integrate with your web app's sync mechanism
  // For now, we'll just mark items as needing sync
  const result = await chrome.storage.local.get(['bookmarks']);
  const bookmarks = result.bookmarks || [];
  
  // In a real implementation, you would:
  // 1. Send unsynced bookmarks to your web app API
  // 2. Mark them as synced when successful
  // 3. Handle conflicts and updates
  
  console.log(`${bookmarks.filter(b => !b.synced).length} bookmarks pending sync`);
}

function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}
