// Content Script for Web App Communication
(function() {
  'use strict';
  
  // Listen for messages from extension
  chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.type === 'NEW_BOOKMARK') {
      handleNewBookmarkFromExtension(message.data);
      sendResponse({ received: true });
    }
  });
  
  // Check if this is the URL Bookmarks web app
  const isWebApp = window.location.hostname.includes('your-web-app-domain.com'); // Update with your domain
  
  if (isWebApp) {
    // Inject extension bridge for web app
    injectExtensionBridge();
  }
  
  function handleNewBookmarkFromExtension(bookmarkData) {
    // If this is the web app, trigger a refresh or add the bookmark directly
    if (isWebApp && window.URLBookmarksApp) {
      window.URLBookmarksApp.addBookmarkFromExtension(bookmarkData);
    }
  }
  
  function injectExtensionBridge() {
    // Create a bridge between extension and web app
    const script = document.createElement('script');
    script.textContent = `
      window.URLBookmarksExtension = {
        isAvailable: true,
        saveBookmark: function(bookmarkData) {
          return new Promise((resolve, reject) => {
            window.postMessage({
              type: 'EXTENSION_SAVE_BOOKMARK',
              data: bookmarkData
            }, '*');
            
            // Listen for response
            const handleResponse = (event) => {
              if (event.data.type === 'EXTENSION_SAVE_RESPONSE') {
                window.removeEventListener('message', handleResponse);
                if (event.data.success) {
                  resolve(event.data.data);
                } else {
                  reject(new Error(event.data.error));
                }
              }
            };
            
            window.addEventListener('message', handleResponse);
            
            // Timeout after 5 seconds
            setTimeout(() => {
              window.removeEventListener('message', handleResponse);
              reject(new Error('Extension timeout'));
            }, 5000);
          });
        }
      };
    `;
    document.documentElement.appendChild(script);
    script.remove();
    
    // Listen for messages from web app
    window.addEventListener('message', (event) => {
      if (event.data.type === 'EXTENSION_SAVE_BOOKMARK') {
        chrome.runtime.sendMessage({
          type: 'SAVE_BOOKMARK',
          data: event.data.data
        }, (response) => {
          window.postMessage({
            type: 'EXTENSION_SAVE_RESPONSE',
            success: response.success,
            data: response.data,
            error: response.error
          }, '*');
        });
      }
    });
  }
})();
