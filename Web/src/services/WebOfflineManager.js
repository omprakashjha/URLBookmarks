// Offline Manager for Web App
class WebOfflineManager {
  constructor() {
    this.isOnline = navigator.onLine;
    this.offlineQueue = [];
    this.listeners = new Set();
    this.dbName = 'StashOffline';
    this.dbVersion = 1;
    
    this.setupEventListeners();
    this.initializeDatabase();
    this.registerServiceWorker();
  }

  setupEventListeners() {
    window.addEventListener('online', () => {
      this.isOnline = true;
      this.notifyListeners('online');
      this.processOfflineQueue();
    });

    window.addEventListener('offline', () => {
      this.isOnline = false;
      this.notifyListeners('offline');
    });
  }

  async initializeDatabase() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.dbVersion);
      
      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve();
      };
      
      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        
        // Operations store
        if (!db.objectStoreNames.contains('operations')) {
          const operationsStore = db.createObjectStore('operations', { keyPath: 'id' });
          operationsStore.createIndex('timestamp', 'timestamp');
        }
        
        // Bookmarks cache store
        if (!db.objectStoreNames.contains('bookmarks')) {
          const bookmarksStore = db.createObjectStore('bookmarks', { keyPath: 'id' });
          bookmarksStore.createIndex('url', 'url');
          bookmarksStore.createIndex('modifiedAt', 'modifiedAt');
        }
      };
    });
  }

  async registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      try {
        const registration = await navigator.serviceWorker.register('/sw.js');
        console.log('Service Worker registered:', registration);
        
        // Listen for service worker messages
        navigator.serviceWorker.addEventListener('message', (event) => {
          if (event.data.type === 'SYNC_COMPLETE') {
            this.notifyListeners('syncComplete', event.data);
          }
        });
        
      } catch (error) {
        console.error('Service Worker registration failed:', error);
      }
    }
  }

  // Queue operations for offline processing
  async queueOperation(type, data) {
    const operation = {
      id: this.generateId(),
      type,
      data,
      timestamp: Date.now(),
      retries: 0
    };

    if (this.isOnline) {
      // Try to process immediately
      try {
        await this.processOperation(operation);
        return { success: true };
      } catch (error) {
        // If immediate processing fails, queue it
        await this.storeOperation(operation);
        return { success: false, queued: true };
      }
    } else {
      // Store for later processing
      await this.storeOperation(operation);
      return { success: false, queued: true };
    }
  }

  async processOperation(operation) {
    const { type, data } = operation;
    
    switch (type) {
      case 'ADD_BOOKMARK':
        return await this.addBookmarkOnline(data);
      case 'UPDATE_BOOKMARK':
        return await this.updateBookmarkOnline(data);
      case 'DELETE_BOOKMARK':
        return await this.deleteBookmarkOnline(data);
      default:
        throw new Error(`Unknown operation type: ${type}`);
    }
  }

  async addBookmarkOnline(bookmarkData) {
    // This would integrate with CloudKit or your API
    console.log('Adding bookmark online:', bookmarkData);
    
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    return { success: true, id: this.generateId() };
  }

  async updateBookmarkOnline(bookmarkData) {
    console.log('Updating bookmark online:', bookmarkData);
    await new Promise(resolve => setTimeout(resolve, 1000));
    return { success: true };
  }

  async deleteBookmarkOnline(bookmarkData) {
    console.log('Deleting bookmark online:', bookmarkData);
    await new Promise(resolve => setTimeout(resolve, 1000));
    return { success: true };
  }

  async storeOperation(operation) {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(['operations'], 'readwrite');
      const store = transaction.objectStore('operations');
      const request = store.add(operation);
      
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  async processOfflineQueue() {
    if (!this.isOnline) return;

    try {
      const operations = await this.getStoredOperations();
      
      for (const operation of operations) {
        try {
          await this.processOperation(operation);
          await this.removeStoredOperation(operation.id);
          this.notifyListeners('operationSynced', operation);
        } catch (error) {
          console.error('Failed to process operation:', operation, error);
          
          // Increment retry count
          operation.retries = (operation.retries || 0) + 1;
          
          if (operation.retries < 3) {
            await this.updateStoredOperation(operation);
          } else {
            // Max retries reached, remove operation
            await this.removeStoredOperation(operation.id);
            this.notifyListeners('operationFailed', operation);
          }
        }
      }
    } catch (error) {
      console.error('Failed to process offline queue:', error);
    }
  }

  async getStoredOperations() {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(['operations'], 'readonly');
      const store = transaction.objectStore('operations');
      const request = store.getAll();
      
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  async removeStoredOperation(id) {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(['operations'], 'readwrite');
      const store = transaction.objectStore('operations');
      const request = store.delete(id);
      
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  async updateStoredOperation(operation) {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(['operations'], 'readwrite');
      const store = transaction.objectStore('operations');
      const request = store.put(operation);
      
      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  // Cache management
  async cacheBookmarks(bookmarks) {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(['bookmarks'], 'readwrite');
      const store = transaction.objectStore('bookmarks');
      
      // Clear existing cache
      store.clear();
      
      // Add new bookmarks
      bookmarks.forEach(bookmark => {
        store.add(bookmark);
      });
      
      transaction.oncomplete = () => resolve();
      transaction.onerror = () => reject(transaction.error);
    });
  }

  async getCachedBookmarks() {
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction(['bookmarks'], 'readonly');
      const store = transaction.objectStore('bookmarks');
      const request = store.getAll();
      
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  // Event listeners
  addListener(callback) {
    this.listeners.add(callback);
    return () => this.listeners.delete(callback);
  }

  notifyListeners(event, data) {
    this.listeners.forEach(callback => {
      try {
        callback(event, data);
      } catch (error) {
        console.error('Listener error:', error);
      }
    });
  }

  // Utility methods
  generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  getConnectionStatus() {
    return {
      isOnline: this.isOnline,
      queueLength: this.offlineQueue.length
    };
  }

  async getOfflineStats() {
    const operations = await this.getStoredOperations();
    const cachedBookmarksCount = (await this.getCachedBookmarks()).length;
    
    return {
      pendingOperations: operations.length,
      cachedBookmarksCount,
      isOnline: this.isOnline
    };
  }
}

// Export for use in React app
export default WebOfflineManager;
