import React, { useState, useEffect, useCallback, useMemo } from 'react';

function VirtualBookmarkList({ bookmarks, onDelete, searchTerm, onBookmarkClick }) {
  const [visibleRange, setVisibleRange] = useState({ start: 0, end: 20 });
  const [containerHeight, setContainerHeight] = useState(600);
  const [scrollTop, setScrollTop] = useState(0);
  
  const ITEM_HEIGHT = 120; // Approximate height of each bookmark item
  const BUFFER_SIZE = 5; // Extra items to render outside visible area
  
  // Calculate visible items based on scroll position
  const visibleItems = useMemo(() => {
    const startIndex = Math.max(0, Math.floor(scrollTop / ITEM_HEIGHT) - BUFFER_SIZE);
    const endIndex = Math.min(
      bookmarks.length,
      Math.ceil((scrollTop + containerHeight) / ITEM_HEIGHT) + BUFFER_SIZE
    );
    
    return {
      startIndex,
      endIndex,
      items: bookmarks.slice(startIndex, endIndex)
    };
  }, [bookmarks, scrollTop, containerHeight]);
  
  // Handle scroll events
  const handleScroll = useCallback((e) => {
    setScrollTop(e.target.scrollTop);
  }, []);
  
  // Handle container resize
  useEffect(() => {
    const handleResize = () => {
      const container = document.getElementById('bookmark-container');
      if (container) {
        setContainerHeight(container.clientHeight);
      }
    };
    
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);
  
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
    if (onBookmarkClick) {
      onBookmarkClick(url);
    }
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

  const totalHeight = bookmarks.length * ITEM_HEIGHT;
  const offsetY = visibleItems.startIndex * ITEM_HEIGHT;

  return (
    <div 
      id="bookmark-container"
      className="virtual-scroll-container"
      style={{ height: '100%', overflow: 'auto' }}
      onScroll={handleScroll}
    >
      <div style={{ height: totalHeight, position: 'relative' }}>
        <div 
          style={{ 
            transform: `translateY(${offsetY}px)`,
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0
          }}
        >
          <div className="bookmarks-grid">
            {visibleItems.items.map((bookmark, index) => {
              const actualIndex = visibleItems.startIndex + index;
              
              return (
                <div
                  key={bookmark.id}
                  className="bookmark-card"
                  onClick={() => handleCardClick(bookmark.url)}
                  style={{ 
                    minHeight: ITEM_HEIGHT,
                    position: 'relative'
                  }}
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
              );
            })}
          </div>
        </div>
      </div>
      
      {/* Scroll indicator */}
      {bookmarks.length > 20 && (
        <div className="scroll-indicator">
          <div 
            className="scroll-thumb"
            style={{
              height: `${Math.max(20, (containerHeight / totalHeight) * 100)}%`,
              top: `${(scrollTop / totalHeight) * 100}%`
            }}
          />
        </div>
      )}
    </div>
  );
}

export default VirtualBookmarkList;
