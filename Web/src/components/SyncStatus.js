import React from 'react';

function SyncStatus({ status }) {
  const getStatusInfo = () => {
    switch (status) {
      case 'syncing':
        return {
          text: 'Syncing...',
          className: 'syncing'
        };
      case 'success':
        return {
          text: 'Synced',
          className: 'success'
        };
      case 'error':
        return {
          text: 'Sync Error',
          className: 'error'
        };
      default:
        return {
          text: 'Synced',
          className: 'idle'
        };
    }
  };

  const statusInfo = getStatusInfo();

  return (
    <div className="sync-status">
      <div className={`sync-indicator ${statusInfo.className}`}></div>
      <span>{statusInfo.text}</span>
    </div>
  );
}

export default SyncStatus;
