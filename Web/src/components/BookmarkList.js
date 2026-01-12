import React from 'react';

function BookmarkList({ bookmarks, onDelete, searchTerm }) {
  const formatDate = (date) => {
    const now = new Date();
    const bookmarkDate = new Date(date);
    const diffTime = Math.abs(now - bookmarkDate);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 1) return 'Today';
    if (diffDays === 2) return 'Yesterday';
    if (diffDays <= 7) return `${diffDays - 1} days ago`;
    
    return bookmarkDate.toLocaleDateString();
  };

  const getFaviconLetter = (url) => {
    try {
      const domain = new URL(url).hostname;
      return domain.charAt(0).toUpperCase();
    } catch {
      return url.charAt(0).toUpperCase();
    }
  };

  const handleCardClick = (url) => {
    window.open(url, '_blank', 'noopener,noreferrer');
  };

  const handleDeleteClick = (e, bookmark) => {
    e.stopPropagation();
    if (window.confirm('Are you sure you want to delete this bookmark?')) {
      onDelete(bookmark);
    }
  };

  if (bookmarks.length === 0) {
    return (
      <div className="empty-state">
        <div className="empty-state-icon">🔖</div>
        <h2 className="empty-state-title">
          {searchTerm ? 'No results found' : 'No bookmarks yet'}
        </h2>
        <p className="empty-state-description">
          {searchTerm 
            ? 'Try a different search term'
            : 'Add your first URL bookmark to get started'
          }
        </p>
      </div>
    );
  }

  return (
    <div className="bookmarks-grid">
      {bookmarks.map((bookmark) => (
        <div
          key={bookmark.id}
          className="bookmark-card"
          onClick={() => handleCardClick(bookmark.url)}
        >
          <div className="bookmark-header">
            <div className="bookmark-favicon">
              {getFaviconLetter(bookmark.url)}
            </div>
            <div className="bookmark-content">
              <h3 className="bookmark-title">
                {bookmark.title || bookmark.url}
              </h3>
              <p className="bookmark-url">{bookmark.url}</p>
              {bookmark.notes && (
                <p className="bookmark-notes">{bookmark.notes}</p>
              )}
              <p className="bookmark-date">
                {formatDate(bookmark.modifiedAt)}
              </p>
            </div>
            <button
              onClick={(e) => handleDeleteClick(e, bookmark)}
              className="close-button"
              style={{ 
                position: 'absolute',
                top: '12px',
                right: '12px',
                fontSize: '16px'
              }}
              title="Delete bookmark"
            >
              ×
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}

export default BookmarkList;
