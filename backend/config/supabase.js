const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseKey = process.env.SUPABASE_KEY || '';

let supabase;

if (supabaseUrl && supabaseKey) {
  try {
    supabase = createClient(supabaseUrl, supabaseKey);
    console.log('✅ Supabase initialized successfully.');
  } catch (error) {
    console.error('❌ Failed to initialize Supabase client:', error.message);
    setupMockSupabase();
  }
} else {
  console.warn('⚠️ SUPABASE_URL or SUPABASE_KEY missing in env. Initializing Mock Supabase Database Layer for local simulation.');
  setupMockSupabase();
}

function setupMockSupabase() {
  // In-memory mocks for local offline development
  const mockStore = {
    matches: [],
    ball_events: [],
    trajectories: [],
    analytics: []
  };

  supabase = {
    from: (table) => ({
      select: () => ({
        eq: () => ({ data: mockStore[table] || [], error: null }),
        order: () => ({ data: mockStore[table] || [], error: null }),
        data: mockStore[table] || [],
        error: null
      }),
      insert: (data) => {
        const items = Array.isArray(data) ? data : [data];
        const inserted = items.map(item => ({ id: Math.random().toString(36).substr(2, 9), ...item, created_at: new Date().toISOString() }));
        if (!mockStore[table]) mockStore[table] = [];
        mockStore[table].push(...inserted);
        return { data: inserted, error: null };
      },
      update: (data) => ({
        eq: () => ({ data: [data], error: null })
      }),
      delete: () => ({
        eq: () => ({ data: [], error: null })
      })
    }),
    storage: {
      from: () => ({
        upload: async (path, body) => ({ data: { path }, error: null }),
        getPublicUrl: (path) => ({ data: { publicUrl: `https://mock-supabase-storage.com/${path}` } })
      })
    }
  };
}

module.exports = supabase;
