// Demo mode configuration
export const DEMO_MODE = process.env.REACT_APP_DEMO_MODE === 'true';

export const DEMO_BOOKMARKS = [
  {
    id: 'demo-1',
    url: 'https://developer.apple.com/documentation/cloudkit',
    title: 'CloudKit Documentation',
    notes: 'Official Apple CloudKit documentation',
    createdAt: new Date('2024-01-01'),
    modifiedAt: new Date('2024-01-01'),
    recordName: 'demo-1'
  },
  {
    id: 'demo-2', 
    url: 'https://reactjs.org',
    title: 'React',
    notes: 'A JavaScript library for building user interfaces',
    createdAt: new Date('2024-01-02'),
    modifiedAt: new Date('2024-01-02'),
    recordName: 'demo-2'
  },
  {
    id: 'demo-3',
    url: 'https://github.com',
    title: 'GitHub',
    notes: 'Where the world builds software',
    createdAt: new Date('2024-01-03'),
    modifiedAt: new Date('2024-01-03'),
    recordName: 'demo-3'
  }
];
