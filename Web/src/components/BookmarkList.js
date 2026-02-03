import React from 'react';

function BookmarkList({ bookmarks, onDelete, searchTerm, viewMode = 'list' }) {
  const extractDomain = (url) => {
    try {
      return new URL(url).hostname.replace('www.', '');
    } catch {
      return '';
    }
  };

  const handleDelete = (e, bookmark) => {
    e.preventDefault();
    e.stopPropagation();
    if (window.confirm('Delete this bookmark?')) {
      onDelete(bookmark);
    }
  };

  if (bookmarks.length === 0) {
    return (
      <div className="empty-state">
        <div className="empty-state-icon">
          {searchTerm ? '🔍' : '🔖'}
        </div>
        <h2 className="empty-state-title">
          {searchTerm ? 'No Results' : 'No Bookmarks'}
        </h2>
        <p className="empty-state-description">
          {searchTerm 
            ? 'Try a different search term' 
            : 'Tap + to add your first URL bookmark'}
        </p>
      </div>
    );
  }

  if (viewMode === 'grid') {
    return (
      <div className="bookmarks-grid">
        {bookmarks.map((bookmark) => (
          <div key={bookmark.id} className="bookmark-card">
            <button
              className="bookmark-card-delete"
              onClick={(e) => handleDelete(e, bookmark)}
              aria-label="Delete bookmark"
            >
              ×
            </button>
            <div className="bookmark-title">
              {bookmark.title || extractDomain(bookmark.url)}
            </div>
            <a 
              href={bookmark.url} 
              target="_blank" 
              rel="noopener noreferrer"
              className="bookmark-url"
              onClick={(e) => e.stopPropagation()}
            >
              {extractDomain(bookmark.url)}
            </a>
            {bookmark.notes && (
              <div className="bookmark-notes">{bookmark.notes}</div>
            )}
          </div>
        ))}
      </div>
    );
  }

  return (
    <ul className="bookmarks-list">
      {bookmarks.map((bookmark) => (
        <li key={bookmark.id} className="bookmark-item">
          <div className="bookmark-info">
            <div className="bookmark-title">
              {bookmark.title || extractDomain(bookmark.url)}
            </div>
            <a 
              href={bookmark.url} 
              target="_blank" 
              rel="noopener noreferrer"
              className="bookmark-url"
              onClick={(e) => e.stopPropagation()}
            >
              {extractDomain(bookmark.url)}
            </a>
            {bookmark.notes && (
              <div className="bookmark-notes">{bookmark.notes}</div>
            )}
          </div>
          <button
            className="bookmark-delete-btn"
            onClick={(e) => handleDelete(e, bookmark)}
            aria-label="Delete bookmark"
          >
            ×
          </button>
        </li>
      ))}
    </ul>
  );
}

export default BookmarkList;
