// CloudKit Web Service Configuration
const CLOUDKIT_CONFIG = {
  containerIdentifier: 'iCloud.com.urlbookmarks.app',
  apiTokenAuth: {
    // This will need to be configured in CloudKit Console
    apiToken: process.env.REACT_APP_CLOUDKIT_API_TOKEN || 'YOUR_API_TOKEN_HERE',
    persist: true,
    signInButton: {
      id: 'apple-sign-in-button',
      theme: 'black'
    },
    signOutButton: {
      id: 'apple-sign-out-button',
      theme: 'black'
    }
  },
  environment: process.env.NODE_ENV === 'production' ? 'production' : 'development'
};

class CloudKitService {
  constructor() {
    this.container = null;
    this.database = null;
    this.isInitialized = false;
    this.isAuthenticated = false;
    this.listeners = new Set();
  }

  async initialize() {
    if (this.isInitialized) return;

    try {
      // Initialize CloudKit
      await window.CloudKit.configure(CLOUDKIT_CONFIG);
      this.container = window.CloudKit.getDefaultContainer();
      this.database = this.container.privateCloudDatabase;
      
      this.isInitialized = true;
      
      // Check authentication status
      const userIdentity = await this.container.whenUserSignsIn();
      if (userIdentity) {
        this.isAuthenticated = true;
        this.notifyListeners('authenticated', userIdentity);
      }
      
      console.log('CloudKit initialized successfully');
    } catch (error) {
      console.error('CloudKit initialization failed:', error);
      throw error;
    }
  }

  async signIn() {
    if (!this.isInitialized) {
      await this.initialize();
    }

    try {
      const userIdentity = await this.container.signIn();
      this.isAuthenticated = true;
      this.notifyListeners('authenticated', userIdentity);
      return userIdentity;
    } catch (error) {
      console.error('CloudKit sign in failed:', error);
      throw error;
    }
  }

  async signOut() {
    if (!this.isInitialized) return;

    try {
      await this.container.signOut();
      this.isAuthenticated = false;
      this.notifyListeners('signedOut');
    } catch (error) {
      console.error('CloudKit sign out failed:', error);
      throw error;
    }
  }

  async fetchBookmarks() {
    if (!this.isAuthenticated) {
      throw new Error('User not authenticated');
    }

    try {
      const query = {
        recordType: 'URLBookmark',
        filterBy: [{
          fieldName: 'isDeleted',
          fieldValue: { value: 0 },
          comparator: 'EQUALS'
        }],
        sortBy: [{
          fieldName: 'modifiedAt',
          ascending: false
        }]
      };

      const response = await this.database.performQuery(query);
      return response.records || [];
    } catch (error) {
      console.error('Failed to fetch bookmarks:', error);
      throw error;
    }
  }

  async saveBookmark(bookmarkData) {
    if (!this.isAuthenticated) {
      throw new Error('User not authenticated');
    }

    try {
      const record = {
        recordType: 'URLBookmark',
        fields: {
          url: { value: bookmarkData.url },
          title: { value: bookmarkData.title || '' },
          notes: { value: bookmarkData.notes || '' },
          createdAt: { value: bookmarkData.createdAt || new Date() },
          modifiedAt: { value: new Date() },
          isDeleted: { value: 0 }
        }
      };

      const response = await this.database.saveRecords([record]);
      return response.records[0];
    } catch (error) {
      console.error('Failed to save bookmark:', error);
      throw error;
    }
  }

  async updateBookmark(recordName, bookmarkData) {
    if (!this.isAuthenticated) {
      throw new Error('User not authenticated');
    }

    try {
      const record = {
        recordName: recordName,
        recordType: 'URLBookmark',
        fields: {
          url: { value: bookmarkData.url },
          title: { value: bookmarkData.title || '' },
          notes: { value: bookmarkData.notes || '' },
          modifiedAt: { value: new Date() },
          isDeleted: { value: 0 }
        }
      };

      const response = await this.database.saveRecords([record]);
      return response.records[0];
    } catch (error) {
      console.error('Failed to update bookmark:', error);
      throw error;
    }
  }

  async deleteBookmark(recordName) {
    if (!this.isAuthenticated) {
      throw new Error('User not authenticated');
    }

    try {
      // Soft delete by setting isDeleted flag
      const record = {
        recordName: recordName,
        recordType: 'URLBookmark',
        fields: {
          isDeleted: { value: 1 },
          modifiedAt: { value: new Date() }
        }
      };

      const response = await this.database.saveRecords([record]);
      return response.records[0];
    } catch (error) {
      console.error('Failed to delete bookmark:', error);
      throw error;
    }
  }

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
  isUserSignedIn() {
    return this.isAuthenticated;
  }

  getAuthenticationState() {
    if (!this.isInitialized) return 'initializing';
    if (!this.isAuthenticated) return 'signedOut';
    return 'signedIn';
  }
}

// Export singleton instance
export default new CloudKitService();
