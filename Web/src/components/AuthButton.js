import React from 'react';

function AuthButton({ isAuthenticated, onSignIn, onSignOut }) {
  if (isAuthenticated) {
    return (
      <button onClick={onSignOut} className="button button-secondary">
        Sign Out
      </button>
    );
  }

  return (
    <button onClick={onSignIn} className="button">
      Sign In with Apple
    </button>
  );
}

export default AuthButton;
