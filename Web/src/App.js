import React, { useState, useEffect, useCallback } from 'react';
import CloudKitService from './services/CloudKitService';
import BookmarkList from './components/BookmarkList';
import AddBookmarkModal from './components/AddBookmarkModal';
import AuthButton from './components/AuthButton';
import SyncStatus from './components/SyncStatus';
import { DEMO_MODE, DEMO_BOOKMARKS } from './config/demo';

const APP_VERSION = process.env.REACT_APP_VERSION || require('../package.json').version;

function App() {
  const [bookmarks, setBookmarks] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [authState, setAuthState] = useState('initializing');
  const [showAddModal, setShowAddModal] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [syncStatus, setSyncStatus] = useState('idle');
  const [showExportMenu, setShowExportMenu] = useState(false);
  const [isDemoMode, setIsDemoMode] = useState(DEMO_MODE);
  const [viewMode, setViewMode] = useState('list'); // 'list' or 'grid'

  const initializeCloudKit = useCallback(async () => {
    if (isDemoMode) {
      setAuthState('signedIn');
      setIsAuthenticated(true);
      setBookmarks(DEMO_BOOKMARKS);
      return;
    }

    try {
      await CloudKitService.initialize();
      setAuthState(CloudKitService.getAuthenticationState());
      setIsAuthenticated(CloudKitService.isUserSignedIn());

      // Add listener for auth changes
      CloudKitService.addListener((event, data) => {
        if (event === 'authenticated') {
          setIsAuthenticated(true);
          setAuthState('signedIn');
          loadBookmarks();
        } else if (event === 'signedOut') {
          setIsAuthenticated(false);
          setAuthState('signedOut');
          setBookmarks([]);
        }
      });

      // Load bookmarks if already authenticated
      if (CloudKitService.isUserSignedIn()) {
        loadBookmarks();
      }
    } catch (error) {
      console.error('CloudKit initialization failed, falling back to demo mode:', error);
      setIsDemoMode(true);
      setAuthState('signedIn');
      setIsAuthenticated(true);
      setBookmarks(DEMO_BOOKMARKS);
    }
  }, [isDemoMode]);

  useEffect(() => {
    initializeCloudKit();
  }, [initializeCloudKit]);

  const loadBookmarks = async () => {
    if (!isAuthenticated) return;

    setIsLoading(true);
    setSyncStatus('syncing');
    
    try {
      const records = await CloudKitService.fetchBookmarks();
      const bookmarkData = records.map(record => ({
        id: record.recordName,
        url: record.fields.url?.value || '',
        title: record.fields.title?.value || '',
        notes: record.fields.notes?.value || '',
        createdAt: record.fields.createdAt?.value || new Date(),
        modifiedAt: record.fields.modifiedAt?.value || new Date(),
        recordName: record.recordName
      }));
      
      setBookmarks(bookmarkData);
      setSyncStatus('success');
      
      // Reset to idle after showing success
      setTimeout(() => setSyncStatus('idle'), 2000);
    } catch (error) {
      console.error('Failed to load bookmarks:', error);
      setSyncStatus('error');
    } finally {
      setIsLoading(false);
    }
  };

  const handleAddBookmark = async (bookmarkData) => {
    try {
      setSyncStatus('syncing');
      
      if (isDemoMode) {
        const newBookmark = {
          id: `demo-${Date.now()}`,
          url: bookmarkData.url,
          title: bookmarkData.title,
          notes: bookmarkData.notes,
          createdAt: new Date(),
          modifiedAt: new Date(),
          recordName: `demo-${Date.now()}`
        };
        
        setBookmarks(prev => [newBookmark, ...prev]);
        setShowAddModal(false);
        setSyncStatus('success');
        setTimeout(() => setSyncStatus('idle'), 2000);
        return;
      }

      const bookmark = {
        url: bookmarkData.url,
        title: bookmarkData.title,
        notes: bookmarkData.notes,
        createdAt: new Date(),
        modifiedAt: new Date()
      };

      const record = await CloudKitService.saveBookmark(bookmark);
      
      const newBookmark = {
        id: record.recordName,
        ...bookmark,
        recordName: record.recordName
      };

      setBookmarks(prev => [newBookmark, ...prev]);
      setShowAddModal(false);
      setSyncStatus('success');
      
      setTimeout(() => setSyncStatus('idle'), 2000);
    } catch (error) {
      console.error('Failed to add bookmark:', error);
      setSyncStatus('error');
    }
  };

  const handleDeleteBookmark = async (bookmark) => {
    try {
      setSyncStatus('syncing');
      
      if (isDemoMode) {
        setBookmarks(prev => prev.filter(b => b.id !== bookmark.id));
        setSyncStatus('success');
        setTimeout(() => setSyncStatus('idle'), 2000);
        return;
      }
      
      await CloudKitService.deleteBookmark(bookmark.recordName);
      
      setBookmarks(prev => prev.filter(b => b.id !== bookmark.id));
      setSyncStatus('success');
      
      setTimeout(() => setSyncStatus('idle'), 2000);
    } catch (error) {
      console.error('Failed to delete bookmark:', error);
      setSyncStatus('error');
    }
  };

  const handleSignIn = async () => {
    try {
      await CloudKitService.signIn();
    } catch (error) {
      console.error('Sign in failed:', error);
    }
  };

  const handleSignOut = async () => {
    try {
      await CloudKitService.signOut();
    } catch (error) {
      console.error('Sign out failed:', error);
    }
  };

  const filteredBookmarks = bookmarks.filter(bookmark => {
    const searchLower = searchTerm.toLowerCase();
    return (
      bookmark.url.toLowerCase().includes(searchLower) ||
      bookmark.title.toLowerCase().includes(searchLower) ||
      bookmark.notes.toLowerCase().includes(searchLower)
    );
  });

  const handleExport = (format = 'json') => {
    const exportData = {
      version: '1.0',
      exportDate: new Date().toISOString(),
      platform: 'Web',
      bookmarks: bookmarks.map(bookmark => ({
        id: bookmark.id,
        url: bookmark.url,
        title: bookmark.title || '',
        notes: bookmark.notes || '',
        createdAt: bookmark.createdAt,
        modifiedAt: bookmark.modifiedAt,
        tags: [],
        metadata: {
          domain: extractDomain(bookmark.url),
          isSecure: bookmark.url.startsWith('https://')
        }
      }))
    };

    let dataStr, filename, mimeType;

    switch (format) {
      case 'csv':
        dataStr = exportAsCSV(exportData.bookmarks);
        filename = `stash-${getDateString()}.csv`;
        mimeType = 'text/csv';
        break;
      
      case 'html':
        dataStr = exportAsHTML(exportData.bookmarks);
        filename = `stash-${getDateString()}.html`;
        mimeType = 'text/html';
        break;
      
      default:
        dataStr = JSON.stringify(exportData, null, 2);
        filename = `stash-${getDateString()}.json`;
        mimeType = 'application/json';
    }

    const dataBlob = new Blob([dataStr], { type: mimeType });
    const url = URL.createObjectURL(dataBlob);
    
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  const exportAsCSV = (bookmarks) => {
    let csvContent = 'URL,Title,Notes,Created,Modified\n';
    
    bookmarks.forEach(bookmark => {
      const title = escapeCSV(bookmark.title || '');
      const notes = escapeCSV(bookmark.notes || '');
      const created = new Date(bookmark.createdAt).toISOString();
      const modified = new Date(bookmark.modifiedAt).toISOString();
      
      csvContent += `"${bookmark.url}","${title}","${notes}","${created}","${modified}"\n`;
    });
    
    return csvContent;
  };

  const exportAsHTML = (bookmarks) => {
    const now = new Date().toLocaleDateString();
    
    let htmlContent = `<!DOCTYPE html>
<html>
<head>
    <title>Stash Export</title>
    <meta charset="utf-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; }
        .bookmark { margin: 16px 0; padding: 12px; border-left: 3px solid #007aff; }
        .title { font-weight: 600; margin-bottom: 4px; }
        .url { color: #007aff; text-decoration: none; }
        .notes { color: #666; font-size: 14px; margin-top: 8px; }
        .date { color: #999; font-size: 12px; }
    </style>
</head>
<body>
    <h1>Stash</h1>
    <p>Exported on ${now}</p>
`;

    bookmarks.forEach(bookmark => {
      htmlContent += `
    <div class="bookmark">
        <div class="title">${htmlEscape(bookmark.title || bookmark.url)}</div>
        <a href="${bookmark.url}" class="url">${bookmark.url}</a>`;
      
      if (bookmark.notes) {
        htmlContent += `<div class="notes">${htmlEscape(bookmark.notes)}</div>`;
      }
      
      htmlContent += `<div class="date">Added: ${new Date(bookmark.createdAt).toLocaleDateString()}</div>
    </div>`;
    });

    htmlContent += '</body></html>';
    return htmlContent;
  };

  const handleImport = (event) => {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (e) => {
      try {
        let importData = [];
        const fileExtension = file.name.split('.').pop().toLowerCase();
        
        switch (fileExtension) {
          case 'csv':
            importData = parseCSV(e.target.result);
            break;
          
          case 'html':
          case 'htm':
            importData = parseHTML(e.target.result);
            break;
          
          default:
            importData = parseJSON(e.target.result);
        }
        
        let imported = 0;
        let skipped = 0;
        
        for (const bookmarkData of importData) {
          if (bookmarkData.url && isValidURL(bookmarkData.url)) {
            // Check for duplicates
            const isDuplicate = bookmarks.some(b => b.url === bookmarkData.url);
            
            if (isDuplicate) {
              skipped++;
            } else {
              await handleAddBookmark(bookmarkData);
              imported++;
            }
          }
        }
        
        alert(`Import complete: ${imported} imported, ${skipped} skipped`);
        
      } catch (error) {
        console.error('Failed to import bookmarks:', error);
        alert('Failed to import bookmarks. Please check the file format.');
      }
    };
    reader.readAsText(file);
    
    // Reset file input
    event.target.value = '';
  };

  const parseJSON = (jsonString) => {
    const data = JSON.parse(jsonString);
    
    // Handle new format
    if (data.bookmarks && Array.isArray(data.bookmarks)) {
      return data.bookmarks;
    }
    
    // Handle array format
    if (Array.isArray(data)) {
      return data;
    }
    
    throw new Error('Invalid JSON format');
  };

  const parseCSV = (csvString) => {
    const lines = csvString.split('\n');
    const bookmarks = [];
    
    // Skip header row
    for (let i = 1; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line) continue;
      
      const fields = parseCSVLine(line);
      if (fields.length >= 2) {
        bookmarks.push({
          url: fields[0],
          title: fields[1] || null,
          notes: fields[2] || null,
          createdAt: new Date().toISOString(),
          modifiedAt: new Date().toISOString()
        });
      }
    }
    
    return bookmarks;
  };

  const parseHTML = (htmlString) => {
    const parser = new DOMParser();
    const doc = parser.parseFromString(htmlString, 'text/html');
    const links = doc.querySelectorAll('a[href]');
    
    return Array.from(links).map(link => ({
      url: link.href,
      title: link.textContent.trim() || null,
      notes: null,
      createdAt: new Date().toISOString(),
      modifiedAt: new Date().toISOString()
    }));
  };

  // Utility functions
  const extractDomain = (url) => {
    try {
      return new URL(url).hostname;
    } catch {
      return '';
    }
  };

  const escapeCSV = (str) => {
    return str.replace(/"/g, '""');
  };

  const htmlEscape = (str) => {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  };

  const parseCSVLine = (line) => {
    const fields = [];
    let currentField = '';
    let inQuotes = false;
    
    for (let i = 0; i < line.length; i++) {
      const char = line[i];
      
      if (char === '"') {
        if (inQuotes && line[i + 1] === '"') {
          currentField += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char === ',' && !inQuotes) {
        fields.push(currentField);
        currentField = '';
      } else {
        currentField += char;
      }
    }
    
    fields.push(currentField);
    return fields;
  };

  const getDateString = () => {
    const now = new Date();
    return now.toISOString().split('T')[0].replace(/-/g, '');
  };

  const isValidURL = (string) => {
    try {
      new URL(string);
      return true;
    } catch {
      return false;
    }
  };

  if (authState === 'initializing') {
    return (
      <div className="container">
        <div className="empty-state">
          <div className="empty-state-icon">⏳</div>
          <h2 className="empty-state-title">Initializing...</h2>
          <p className="empty-state-description">Setting up CloudKit connection</p>
        </div>
      </div>
    );
  }

  if (authState === 'error') {
    return (
      <div className="container">
        <div className="empty-state">
          <div className="empty-state-icon">⚠️</div>
          <h2 className="empty-state-title">Connection Error</h2>
          <p className="empty-state-description">
            Failed to connect to CloudKit. Please check your configuration.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div>
      <header className="header">
        <div className="header-content">
          <h1 className="logo">
            Stash
            {isDemoMode && <span className="demo-badge">Demo</span>}
          </h1>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            {isAuthenticated && <SyncStatus status={syncStatus} />}
            {!isDemoMode && (
              <AuthButton
                isAuthenticated={isAuthenticated}
                onSignIn={handleSignIn}
                onSignOut={handleSignOut}
              />
            )}
          </div>
        </div>
      </header>

      <div className="container">
        {!isAuthenticated && !isDemoMode ? (
          <div className="empty-state">
            <div className="empty-state-icon">🔐</div>
            <h2 className="empty-state-title">Sign In Required</h2>
            <p className="empty-state-description">
              Sign in with your Apple ID to access your bookmarks
            </p>
          </div>
        ) : (
          <>
            <div className="search-container">
              <input
                type="text"
                placeholder="Search"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="search-input"
              />
            </div>

            <div className="toolbar">
              <button
                onClick={() => setShowAddModal(true)}
                className="button"
              >
                + Add
              </button>
              <button
                onClick={loadBookmarks}
                className="button button-secondary"
                disabled={isLoading}
              >
                {isLoading ? 'Syncing...' : 'Refresh'}
              </button>
              
              <div style={{ position: 'relative' }}>
                <button
                  onClick={() => setShowExportMenu(!showExportMenu)}
                  className="button button-secondary"
                  disabled={bookmarks.length === 0}
                >
                  Export
                </button>
                {showExportMenu && (
                  <div style={{
                    position: 'absolute',
                    top: '100%',
                    left: 0,
                    marginTop: '4px',
                    background: 'white',
                    border: '0.5px solid rgba(0, 0, 0, 0.1)',
                    borderRadius: '10px',
                    boxShadow: '0 4px 16px rgba(0, 0, 0, 0.15)',
                    zIndex: 1000,
                    minWidth: '120px',
                    overflow: 'hidden'
                  }}>
                    <button
                      onClick={() => { handleExport('json'); setShowExportMenu(false); }}
                      style={{ 
                        display: 'block', 
                        width: '100%', 
                        padding: '10px 12px', 
                        border: 'none', 
                        background: 'none', 
                        textAlign: 'left', 
                        cursor: 'pointer',
                        fontSize: '15px'
                      }}
                      onMouseEnter={(e) => e.target.style.background = '#f2f2f7'}
                      onMouseLeave={(e) => e.target.style.background = 'none'}
                    >
                      JSON
                    </button>
                    <button
                      onClick={() => { handleExport('csv'); setShowExportMenu(false); }}
                      style={{ 
                        display: 'block', 
                        width: '100%', 
                        padding: '10px 12px', 
                        border: 'none', 
                        background: 'none', 
                        textAlign: 'left', 
                        cursor: 'pointer',
                        fontSize: '15px'
                      }}
                      onMouseEnter={(e) => e.target.style.background = '#f2f2f7'}
                      onMouseLeave={(e) => e.target.style.background = 'none'}
                    >
                      CSV
                    </button>
                    <button
                      onClick={() => { handleExport('html'); setShowExportMenu(false); }}
                      style={{ 
                        display: 'block', 
                        width: '100%', 
                        padding: '10px 12px', 
                        border: 'none', 
                        background: 'none', 
                        textAlign: 'left', 
                        cursor: 'pointer',
                        fontSize: '15px'
                      }}
                      onMouseEnter={(e) => e.target.style.background = '#f2f2f7'}
                      onMouseLeave={(e) => e.target.style.background = 'none'}
                    >
                      HTML
                    </button>
                  </div>
                )}
              </div>
              
              <label className="button button-secondary" style={{ cursor: 'pointer', margin: 0 }}>
                Import
                <input
                  type="file"
                  accept=".json,.csv,.html,.htm"
                  onChange={handleImport}
                  style={{ display: 'none' }}
                />
              </label>

              <button
                onClick={() => setViewMode(viewMode === 'list' ? 'grid' : 'list')}
                className="view-toggle-single"
                title={viewMode === 'list' ? 'Grid view' : 'List view'}
              >
                {viewMode === 'list' ? '⊞' : '☰'}
              </button>
            </div>

            <BookmarkList
              bookmarks={filteredBookmarks}
              onDelete={handleDeleteBookmark}
              searchTerm={searchTerm}
              viewMode={viewMode}
            />

            {showAddModal && (
              <AddBookmarkModal
                onSave={handleAddBookmark}
                onClose={() => setShowAddModal(false)}
              />
            )}
          </>
        )}
      </div>
      
      <footer style={{ 
        textAlign: 'center', 
        padding: '20px', 
        color: '#999', 
        fontSize: '12px',
        borderTop: '1px solid #e5e5ea'
      }}>
        Stash v{APP_VERSION}
      </footer>
    </div>
  );
}

export default App;
