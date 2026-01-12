import React, { useState, useEffect } from 'react';

function AddBookmarkModal({ onSave, onClose }) {
  const [url, setUrl] = useState('');
  const [title, setTitle] = useState('');
  const [notes, setNotes] = useState('');
  const [isValidUrl, setIsValidUrl] = useState(true);

  useEffect(() => {
    // Check clipboard for URL
    if (navigator.clipboard && navigator.clipboard.readText) {
      navigator.clipboard.readText()
        .then(text => {
          if (isValidURL(text)) {
            setUrl(text);
            fetchTitle(text);
          }
        })
        .catch(() => {
          // Clipboard access denied, ignore
        });
    }
  }, []);

  const isValidURL = (string) => {
    try {
      new URL(string);
      return true;
    } catch {
      return false;
    }
  };

  const fetchTitle = async (urlString) => {
    try {
      // Extract domain as fallback title
      const urlObj = new URL(urlString);
      setTitle(urlObj.hostname.replace('www.', ''));
    } catch {
      // Invalid URL, ignore
    }
  };

  const handleUrlChange = (e) => {
    const newUrl = e.target.value;
    setUrl(newUrl);
    setIsValidUrl(isValidURL(newUrl) || newUrl === '');
    
    if (isValidURL(newUrl) && !title) {
      fetchTitle(newUrl);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    if (!url || !isValidUrl) return;

    const bookmarkData = {
      url: url.trim(),
      title: title.trim() || null,
      notes: notes.trim() || null,
      createdAt: new Date(),
      modifiedAt: new Date()
    };

    onSave(bookmarkData);
  };

  const handleOverlayClick = (e) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  };

  return (
    <div className="modal-overlay" onClick={handleOverlayClick}>
      <div className="modal">
        <div className="modal-header">
          <h2 className="modal-title">Add Bookmark</h2>
          <button onClick={onClose} className="close-button">
            ×
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">URL *</label>
            <input
              type="url"
              value={url}
              onChange={handleUrlChange}
              placeholder="https://example.com"
              className="form-input"
              required
              autoFocus
            />
            {!isValidUrl && (
              <div style={{ color: '#ff3b30', fontSize: '14px', marginTop: '4px' }}>
                Please enter a valid URL
              </div>
            )}
          </div>

          <div className="form-group">
            <label className="form-label">Title</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Website title"
              className="form-input"
            />
          </div>

          <div className="form-group">
            <label className="form-label">Notes</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Add notes about this URL"
              className="form-input form-textarea"
              rows={3}
            />
          </div>

          <div className="form-actions">
            <button
              type="button"
              onClick={onClose}
              className="button button-secondary"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="button"
              disabled={!url || !isValidUrl}
            >
              Save Bookmark
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default AddBookmarkModal;
