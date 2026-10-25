/**
 * Frontend JavaScript Controller
 * Course: 25CS301 - Artificial Intelligence
 * Manages Vis.js Force-Directed Graph, Chart.js benchmarks, MST/Topological visualizers,
 * and REST API client requests.
 */

// Application State
const STATE = {
  users: [],
  connections: [],
  mentorships: [],
  usersMap: {},
  activeUserId: "u1",
  mainNetwork: null,
  mstNetwork: null,
  charts: {
    accuracy: null,
    scalability: null
  }
};

// Department color map
const DEPT_COLORS = {
  "Computer Science & Eng": "#6366f1", // Indigo
  "Information Technology": "#38bdf8", // Sky
  "Artificial Intelligence & Data Science": "#10b981", // Emerald
  "Cybersecurity & Forensic": "#f43f5e", // Rose
  "Electronics & Communication": "#f59e0b" // Amber
};

// Toast notification helper
function showToast(message, type = "success") {
  const container = document.getElementById("toast-container");
  const toast = document.createElement("div");
  const isSuccess = type === "success";
  
  toast.className = `p-3 rounded-xl border text-xs font-semibold flex items-center gap-2 shadow-xl transform transition-all duration-300 pointer-events-auto ${
    isSuccess ? "bg-emerald-950/90 text-emerald-200 border-emerald-700/60" : "bg-rose-950/90 text-rose-200 border-rose-700/60"
  }`;
  toast.innerHTML = `<i class="fa-solid ${isSuccess ? 'fa-circle-check' : 'fa-circle-exclamation'}"></i> <span>${message}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.classList.add("opacity-0", "translate-y-2");
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// =====================================================================
// 1. INITIALIZATION & DATA FETCHING
// =====================================================================
document.addEventListener("DOMContentLoaded", async () => {
  setupTabs();
  setupModal();
  renderVivaAccordion();
  await loadGraphState();
  initMainNetwork();
  setupEventListeners();
  // Auto-run benchmarks on load for convenience
  await loadAndRenderBenchmarks();
});

async function loadGraphState() {
  try {
    const res = await fetch('/api/graph/state');
    const data = await res.json();
    if (data.status === 'success') {
      STATE.users = data.users;
      STATE.connections = data.connections;
      STATE.mentorships = data.mentorships;
      
      STATE.usersMap = {};
      data.users.forEach(u => {
        STATE.usersMap[u.id] = u;
      });

      // Update header counters
      document.getElementById('header-node-count').innerText = data.stats.total_users;
      document.getElementById('header-edge-count').innerText = data.stats.total_connections;

      populateUserSelector();
    }
  } catch (err) {
    console.error("Error loading graph state:", err);
  }
}

function populateUserSelector() {
  const select = document.getElementById('select-active-user');
  select.innerHTML = '';
  STATE.users.forEach(u => {
    const opt = document.createElement('option');
    opt.value = u.id;
    opt.textContent = `${u.name} (${u.department.split('&')[0].trim()})`;
    if (u.id === STATE.activeUserId) opt.selected = true;
    select.appendChild(opt);
  });
}

// =====================================================================
// 2. TAB SWITCHING LOGIC
// =====================================================================
function setupTabs() {
  const tabButtons = document.querySelectorAll('.tab-btn');
  const panes = document.querySelectorAll('.tab-pane');

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-tab');

      tabButtons.forEach(b => {
        b.classList.remove('active', 'bg-brand-accent/20', 'text-brand-accent', 'border-brand-accent/40');
        b.classList.add('text-slate-400');
      });
      btn.classList.add('active', 'bg-brand-accent/20', 'text-brand-accent', 'border-brand-accent/40');
      btn.classList.remove('text-slate-400');

      panes.forEach(p => p.classList.add('hidden'));
      const activePane = document.getElementById(targetId);
      if (activePane) activePane.classList.remove('hidden');

      // Trigger redraws if switching to graph tabs
      if (targetId === 'tab-mst') {
        runMSTVisualization('kruskal');
      } else if (targetId === 'tab-recommender' && STATE.mainNetwork) {
        STATE.mainNetwork.fit();
      }
    });
  });

  // Sub-view switcher in Tab 2 (MST vs Topological)
  const btnSubMst = document.getElementById('btn-sub-mst');
  const btnSubTopo = document.getElementById('btn-sub-topo');
  const subviewMst = document.getElementById('subview-mst-content');
  const subviewTopo = document.getElementById('subview-topo-content');

  btnSubMst.addEventListener('click', () => {
    btnSubMst.className = "px-3 py-1.5 text-xs font-semibold rounded-lg bg-brand-accent text-white transition";
    btnSubTopo.className = "px-3 py-1.5 text-xs font-semibold rounded-lg text-slate-400 hover:text-white transition";
    subviewMst.classList.remove('hidden');
    subviewTopo.classList.add('hidden');
    if (STATE.mstNetwork) STATE.mstNetwork.fit();
  });

  btnSubTopo.addEventListener('click', () => {
    btnSubTopo.className = "px-3 py-1.5 text-xs font-semibold rounded-lg bg-brand-accent text-white transition";
    btnSubMst.className = "px-3 py-1.5 text-xs font-semibold rounded-lg text-slate-400 hover:text-white transition";
    subviewTopo.classList.remove('hidden');
    subviewMst.classList.add('hidden');
    runTopologicalSort('kahns');
  });
}

// =====================================================================
// 3. VIS.JS MAIN GRAPH & RECOMMENDATION INTEGRATION
// =====================================================================
function initMainNetwork() {
  const container = document.getElementById('network-canvas');
  if (!container) return;

  const nodes = new vis.DataSet(
    STATE.users.map(u => ({
      id: u.id,
      label: u.name,
      shape: 'circularImage',
      image: u.avatar || `https://api.dicebear.com/7.x/bottts/svg?seed=${u.name}`,
      borderWidth: u.id === STATE.activeUserId ? 4 : 2,
      color: {
        border: u.id === STATE.activeUserId ? '#f59e0b' : (DEPT_COLORS[u.department] || '#6366f1'),
        background: '#1e293b',
        highlight: { border: '#f59e0b', background: '#334155' }
      },
      font: { color: '#e2e8f0', size: 12, face: 'Plus Jakarta Sans', strokeWidth: 3, strokeColor: '#0b0f19' },
      title: `${u.name} | ${u.role} (${u.department})`
    }))
  );

  const edges = new vis.DataSet(
    STATE.connections.map((c, idx) => ({
      id: `e_${idx}`,
      from: c[0],
      to: c[1],
      width: Math.max(1, (c[2] || 5) / 2.5),
      color: { color: '#334155', highlight: '#06b6d4', hover: '#06b6d4' },
      title: `Strength: ${c[2]}/10 (${c[3] || 'Connected'})`
    }))
  );

  const options = {
    nodes: { size: 22 },
    edges: { smooth: { type: 'continuous' } },
    physics: {
      solver: 'forceAtlas2Based',
      forceAtlas2Based: {
        gravitationalConstant: -38,
        centralGravity: 0.008,
        springLength: 100,
        springConstant: 0.08
      },
      stabilization: { iterations: 120 }
    },
    interaction: { hover: true, tooltipDelay: 100 }
  };

  STATE.mainNetwork = new vis.Network(container, { nodes, edges }, options);

  // Graph click handler
  STATE.mainNetwork.on('click', (params) => {
    if (params.nodes.length > 0) {
      const selectedId = params.nodes[0];
      selectUser(selectedId);
    }
  });

  // Load recommendations for initial user
  selectUser(STATE.activeUserId);
}

async function selectUser(userId) {
  STATE.activeUserId = userId;
  document.getElementById('select-active-user').value = userId;

  const user = STATE.usersMap[userId];
  if (!user) return;

  // Update profile card in right panel
  renderActiveUserProfileCard(user);

  // Highlight ego network on canvas
  highlightEgoNetwork(userId);

  // Fetch recommendations
  await fetchAndRenderRecommendations(userId);
}

function renderActiveUserProfileCard(user) {
  const container = document.getElementById('active-user-profile-card');
  const deptColor = DEPT_COLORS[user.department] || '#6366f1';

  // Compute node degree
  const directFriends = STATE.connections.filter(c => c[0] === user.id || c[1] === user.id);
  document.getElementById('metric-node-degree').innerText = directFriends.length;
  document.getElementById('metric-node-dept').innerText = `${user.name} • ${user.department}`;

  container.innerHTML = `
    <div class="flex items-center gap-3">
      <img src="${user.avatar}" class="w-12 h-12 rounded-xl bg-slate-800 border-2" style="border-color: ${deptColor}">
      <div>
        <h4 class="font-bold text-white text-sm">${user.name}</h4>
        <p class="text-slate-400 text-[11px]">${user.role} • ${user.year}</p>
        <span class="inline-block mt-1 text-[10px] px-2 py-0.5 rounded font-medium" style="background: ${deptColor}22; color: ${deptColor}; border: 1px solid ${deptColor}55;">
          ${user.department}
        </span>
      </div>
    </div>
    <div class="mt-3 pt-3 border-t border-brand-border space-y-1.5 text-[11px]">
      <div><span class="text-slate-500">Skills:</span> <span class="text-slate-300 font-medium">${(user.skills || []).join(', ')}</span></div>
      <div><span class="text-slate-500">Interests:</span> <span class="text-slate-300">${(user.interests || []).join(', ')}</span></div>
      <div class="flex items-center justify-between text-slate-400 pt-1">
        <span>Influence Rank: <strong class="text-brand-cyan font-mono">${user.influence_rank || 80}/100</strong></span>
        <span>Friends: <strong class="text-emerald-400 font-mono">${directFriends.length}</strong></span>
      </div>
    </div>
  `;
}

function highlightEgoNetwork(userId) {
  if (!STATE.mainNetwork) return;

  const directNeighbors = new Set();
  STATE.connections.forEach(c => {
    if (c[0] === userId) directNeighbors.add(c[1]);
    if (c[1] === userId) directNeighbors.add(c[0]);
  });

  // Collect 2-hop
  const secondHop = new Set();
  STATE.connections.forEach(c => {
    if (directNeighbors.has(c[0]) && c[1] !== userId) secondHop.add(c[1]);
    if (directNeighbors.has(c[1]) && c[0] !== userId) secondHop.add(c[0]);
  });

  const nodeUpdates = STATE.users.map(u => {
    let borderColor = DEPT_COLORS[u.department] || '#6366f1';
    let borderWidth = 2;
    let opacity = 0.35;

    if (u.id === userId) {
      borderColor = '#f59e0b';
      borderWidth = 5;
      opacity = 1.0;
    } else if (directNeighbors.has(u.id)) {
      borderColor = '#10b981';
      borderWidth = 3;
      opacity = 1.0;
    } else if (secondHop.has(u.id)) {
      opacity = 0.7;
    }

    return {
      id: u.id,
      borderWidth: borderWidth,
      color: {
        border: borderColor,
        background: opacity < 0.5 ? '#0f172a' : '#1e293b'
      },
      opacity: opacity
    };
  });

  STATE.mainNetwork.body.data.nodes.update(nodeUpdates);
}

// Fetch recommendations
async function fetchAndRenderRecommendations(userId) {
  const container = document.getElementById('recs-container');
  container.innerHTML = `
    <div class="text-center py-8 text-slate-500 text-xs">
      <i class="fa-solid fa-spinner fa-spin text-base text-brand-cyan mb-2"></i>
      <p>Calculating Jaccard, Adamic-Adar & Cosine Vectors...</p>
    </div>
  `;

  try {
    const res = await fetch(`/api/recommendations/${userId}?top_n=5`);
    const data = await res.json();

    if (data.status === 'success' && data.recommendations.length > 0) {
      renderRecommendationCards(data.recommendations);
    } else {
      container.innerHTML = `
        <div class="text-center py-8 text-slate-500 text-xs">
          <i class="fa-solid fa-user-check text-xl text-emerald-400 mb-2"></i>
          <p>No new candidate recommendations for this student.</p>
        </div>
      `;
    }
  } catch (err) {
    console.error("Error fetching recs:", err);
  }
}

function renderRecommendationCards(recs) {
  const container = document.getElementById('recs-container');
  container.innerHTML = '';

  recs.forEach(r => {
    const card = document.createElement('div');
    card.className = "bg-slate-900/90 border border-brand-border hover:border-brand-cyan/60 rounded-xl p-3.5 space-y-2.5 transition";
    
    // Score color
    let scoreColor = "text-emerald-400";
    if (r.match_score < 70) scoreColor = "text-amber-400";
    if (r.match_score < 50) scoreColor = "text-slate-400";

    // Badges HTML
    const badgesHtml = (r.explainable_badges || []).map(b => `
      <span class="badge-pill bg-brand-cyan/15 text-brand-cyan border border-brand-cyan/30 text-[10px]">
        <i class="fa-solid fa-tag text-[8px]"></i> ${b}
      </span>
    `).join(' ');

    // Path string
    const pathHtml = r.intro_path_names && r.intro_path_names.length > 1
      ? `<span class="text-[10px] text-amber-300 font-mono"><i class="fa-solid fa-route mr-1"></i>Path: ${r.intro_path_names.join(' → ')}</span>`
      : '';

    card.innerHTML = `
      <div class="flex items-start justify-between gap-2">
        <div class="flex items-center gap-2.5">
          <img src="${r.avatar}" class="w-9 h-9 rounded-lg bg-slate-800 border border-slate-700">
          <div>
            <h5 class="font-bold text-white text-xs">${r.name}</h5>
            <p class="text-[10px] text-slate-400">${r.role} (${r.year.split(' ')[0]})</p>
          </div>
        </div>
        <div class="text-right">
          <span class="text-sm font-extrabold ${scoreColor} font-mono">${r.match_score}%</span>
          <p class="text-[9px] text-slate-500 font-semibold uppercase tracking-wider">AI Match</p>
        </div>
      </div>

      <!-- Metric Pills -->
      <div class="flex flex-wrap gap-1">
        ${badgesHtml}
      </div>

      ${pathHtml ? `<div class="bg-amber-950/20 border border-amber-900/40 px-2 py-1 rounded-lg">${pathHtml}</div>` : ''}

      <!-- Action buttons -->
      <div class="flex items-center justify-between pt-1 border-t border-brand-border/60">
        <span class="text-[10px] text-slate-500 font-mono">Adamic-Adar: ${r.adamic_adar_index}</span>
        <button class="btn-connect-now text-[11px] bg-brand-cyan/20 hover:bg-brand-cyan text-brand-cyan hover:text-slate-900 font-semibold px-2.5 py-1 rounded-lg border border-brand-cyan/40 transition flex items-center gap-1" data-target="${r.candidate_id}">
          <i class="fa-solid fa-user-plus text-[10px]"></i>
          <span>Connect Now</span>
        </button>
      </div>
    `;

    // Connect button listener
    const connectBtn = card.querySelector('.btn-connect-now');
    connectBtn.addEventListener('click', () => connectUsers(STATE.activeUserId, r.candidate_id));

    container.appendChild(card);
  });
}

async function connectUsers(sourceId, targetId) {
  try {
    const res = await fetch('/api/graph/edge/add', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ source: sourceId, target: targetId, strength: 8, label: 'AI Direct Match' })
    });
    const data = await res.json();
    if (data.status === 'success') {
      showToast(`Connected with ${STATE.usersMap[targetId]?.name || targetId}!`);
      await loadGraphState();
      initMainNetwork();
      selectUser(sourceId);
    } else {
      showToast(data.message || 'Connection already exists', 'error');
    }
  } catch (err) {
    showToast('Failed to connect users', 'error');
  }
}

// =====================================================================
// 4. MST & TOPOLOGICAL SORT VISUALIZERS (TAB 2)
// =====================================================================
async function runMSTVisualization(algo = 'kruskal') {
  const container = document.getElementById('mst-canvas');
  const title = document.getElementById('mst-canvas-title');
  const btnKruskal = document.getElementById('btn-run-kruskal');
  const btnPrim = document.getElementById('btn-run-prim');

  if (algo === 'prim') {
    btnPrim.className = "flex-1 py-1.5 text-xs font-semibold rounded-lg bg-brand-cyan text-slate-900 font-mono transition";
    btnKruskal.className = "flex-1 py-1.5 text-xs font-semibold rounded-lg bg-slate-800 text-slate-300 hover:text-white font-mono transition";
    title.innerText = "Prim's Minimum Spanning Tree (Priority Queue Frontier)";
  } else {
    btnKruskal.className = "flex-1 py-1.5 text-xs font-semibold rounded-lg bg-brand-cyan text-slate-900 font-mono transition";
    btnPrim.className = "flex-1 py-1.5 text-xs font-semibold rounded-lg bg-slate-800 text-slate-300 hover:text-white font-mono transition";
    title.innerText = "Kruskal's Minimum Spanning Tree (Disjoint Set Union - DSU)";
  }

  try {
    const res = await fetch(`/api/algorithms/mst?algo=${algo}&start_node=${STATE.activeUserId}`);
    const data = await res.json();
    if (data.status === 'success') {
      const result = data.result;
      
      document.getElementById('mst-total-cost').innerText = result.total_cost;
      document.getElementById('mst-pruned-count').innerText = `${result.edges_pruned} Edges`;
      document.getElementById('mst-pruned-pct').innerText = `${result.prune_percentage}% Redundancy Pruned`;
      document.getElementById('mst-runtime').innerText = `${result.execution_time_ms} ms`;
      document.getElementById('mst-complexity').innerText = result.time_complexity;
      document.getElementById('mst-step-count').innerText = `${result.steps.length} Steps Logged`;

      // Render MST network canvas
      renderMSTNetwork(result.mst_edges);

      // Render execution log
      renderMSTStepLog(result.steps);
    }
  } catch (err) {
    console.error("Error running MST:", err);
  }
}

function renderMSTNetwork(mstEdges) {
  const container = document.getElementById('mst-canvas');
  const mstEdgeSet = new Set(mstEdges.map(e => `${Math.min(e.source, e.target)}-${Math.max(e.source, e.target)}`));

  const nodes = new vis.DataSet(
    STATE.users.map(u => ({
      id: u.id,
      label: u.name,
      shape: 'circularImage',
      image: u.avatar || `https://api.dicebear.com/7.x/bottts/svg?seed=${u.name}`,
      borderWidth: 2,
      color: { border: DEPT_COLORS[u.department] || '#6366f1', background: '#1e293b' },
      font: { color: '#e2e8f0', size: 11, face: 'Plus Jakarta Sans', strokeWidth: 3, strokeColor: '#0b0f19' }
    }))
  );

  // Mark MST edges with glowing vibrant cyan/emerald, and non-MST edges dimmed
  const edges = new vis.DataSet(
    STATE.connections.map((c, idx) => {
      const key = `${Math.min(c[0], c[1])}-${Math.max(c[0], c[1])}`;
      const isMst = mstEdgeSet.has(key);

      return {
        id: `mst_e_${idx}`,
        from: c[0],
        to: c[1],
        width: isMst ? 3.5 : 1,
        color: isMst 
          ? { color: '#10b981', highlight: '#06b6d4', opacity: 1.0 } 
          : { color: '#1e293b', opacity: 0.15 },
        dashes: !isMst
      };
    })
  );

  const options = {
    nodes: { size: 20 },
    physics: {
      solver: 'forceAtlas2Based',
      forceAtlas2Based: { gravitationalConstant: -35, centralGravity: 0.01, springLength: 90 },
      stabilization: { iterations: 100 }
    }
  };

  STATE.mstNetwork = new vis.Network(container, { nodes, edges }, options);
}

function renderMSTStepLog(steps) {
  const container = document.getElementById('mst-steps-log');
  container.innerHTML = '';

  steps.forEach(s => {
    const item = document.createElement('div');
    const isAdded = s.action === 'ADDED';
    item.className = `p-2 rounded-lg border text-[11px] leading-tight ${
      isAdded ? 'bg-emerald-950/30 border-emerald-800/40 text-emerald-200' : 'bg-rose-950/30 border-rose-800/40 text-rose-200'
    }`;
    item.innerHTML = `
      <div class="flex items-center justify-between font-bold">
        <span>Step #${s.step}: ${s.edge || s.node}</span>
        <span class="${isAdded ? 'text-emerald-400' : 'text-rose-400'}">${s.action}</span>
      </div>
      <p class="text-[10px] text-slate-400 mt-0.5">${s.reason}</p>
    `;
    container.appendChild(item);
  });
}

async function runTopologicalSort(algo = 'kahns') {
  const btnKahn = document.getElementById('btn-topo-kahn');
  const btnDfs = document.getElementById('btn-topo-dfs');

  if (algo === 'dfs') {
    btnDfs.className = "flex-1 py-1.5 text-xs font-semibold rounded-lg bg-brand-accent text-white font-mono transition";
    btnKahn.className = "flex-1 py-1.5 text-xs font-semibold rounded-lg bg-slate-800 text-slate-300 hover:text-white font-mono transition";
  } else {
    btnKahn.className = "flex-1 py-1.5 text-xs font-semibold rounded-lg bg-brand-accent text-white font-mono transition";
    btnDfs.className = "flex-1 py-1.5 text-xs font-semibold rounded-lg bg-slate-800 text-slate-300 hover:text-white font-mono transition";
  }

  try {
    const res = await fetch(`/api/algorithms/topological-sort?algo=${algo}`);
    const data = await res.json();
    if (data.status === 'success') {
      const result = data.result;

      // Cycle badge
      const cycleBadge = document.getElementById('topo-cycle-badge');
      if (result.has_cycle) {
        cycleBadge.className = "text-base font-bold text-rose-400 mt-1 flex items-center gap-1.5";
        cycleBadge.innerHTML = `<i class="fa-solid fa-triangle-exclamation"></i> <span>Cycle Detected! Not a pure DAG</span>`;
      } else {
        cycleBadge.className = "text-base font-bold text-emerald-400 mt-1 flex items-center gap-1.5";
        cycleBadge.innerHTML = `<i class="fa-solid fa-circle-check"></i> <span>Acyclic Directed Graph (DAG Valid)</span>`;
      }

      // Root count
      const roots = result.hierarchy_layers && result.hierarchy_layers.length > 0 ? result.hierarchy_layers[0].length : 0;
      document.getElementById('topo-root-count').innerText = `${roots} Mentors`;

      // Render layered hierarchy UI
      renderTopologicalLayers(result.hierarchy_layers);

      // Render indegree table
      renderInDegreeTable(result.initial_in_degrees);
    }
  } catch (err) {
    console.error("Error in topological sort:", err);
  }
}

function renderTopologicalLayers(layers) {
  const container = document.getElementById('topo-hierarchy-layers');
  container.innerHTML = '';

  if (!layers || layers.length === 0) {
    container.innerHTML = '<div class="text-xs text-slate-500">No hierarchy layers to display.</div>';
    return;
  }

  const layerTitles = [
    "Tier 0: Foundational Mentors & Domain Leads (In-degree = 0)",
    "Tier 1: Senior Fellows & Research Leads",
    "Tier 2: Intermediate Collaborators & Associates",
    "Tier 3: Emerging Scholars & Mentees"
  ];

  layers.forEach((layerNodes, idx) => {
    const layerBlock = document.createElement('div');
    layerBlock.className = "p-4 rounded-xl bg-slate-900/80 border border-brand-border space-y-3";
    
    const titleText = layerTitles[idx] || `Tier ${idx}: Dependent Skill Cohort`;
    
    const nodesHtml = layerNodes.map(nid => {
      const u = STATE.usersMap[nid] || { name: nid, role: "Student", department: "General" };
      return `
        <div class="flex items-center gap-2 bg-brand-surface border border-brand-border/80 px-3 py-2 rounded-xl text-xs">
          <img src="${u.avatar || `https://api.dicebear.com/7.x/bottts/svg?seed=${u.name}`}" class="w-7 h-7 rounded-lg bg-slate-800">
          <div>
            <h6 class="font-bold text-white text-xs">${u.name}</h6>
            <p class="text-[10px] text-slate-400">${u.role}</p>
          </div>
        </div>
      `;
    }).join('');

    layerBlock.innerHTML = `
      <div class="flex items-center justify-between">
        <h5 class="text-xs font-bold text-brand-cyan uppercase tracking-wider font-mono">${titleText}</h5>
        <span class="text-[10px] bg-slate-800 text-slate-400 px-2 py-0.5 rounded font-mono">${layerNodes.length} nodes</span>
      </div>
      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2.5 pt-1">
        ${nodesHtml}
      </div>
    `;

    container.appendChild(layerBlock);
  });
}

function renderInDegreeTable(inDegrees) {
  const tbody = document.getElementById('topo-indegree-tbody');
  tbody.innerHTML = '';

  Object.entries(inDegrees || {}).sort((a, b) => a[1] - b[1]).forEach(([uid, deg]) => {
    const u = STATE.usersMap[uid] || { name: uid, department: "Unknown", role: "Student" };
    const tr = document.createElement('tr');
    tr.className = "hover:bg-slate-800/40 transition";
    
    let tierRole = "Mentee / Junior";
    if (deg === 0) tierRole = "Root Mentor (Level 0)";
    else if (deg === 1) tierRole = "Direct Protégé (Level 1)";

    tr.innerHTML = `
      <td class="p-2.5 font-bold text-slate-400">${uid}</td>
      <td class="p-2.5 font-bold text-white">${u.name}</td>
      <td class="p-2.5 text-slate-400">${u.department}</td>
      <td class="p-2.5">
        <span class="px-2 py-0.5 rounded font-bold ${deg === 0 ? 'bg-emerald-950 text-emerald-400 border border-emerald-800' : 'bg-slate-800 text-slate-300'}">
          ${deg}
        </span>
      </td>
      <td class="p-2.5 text-brand-cyan">${tierRole}</td>
    `;
    tbody.appendChild(tr);
  });
}

// =====================================================================
// 5. BENCHMARKS & EVALUATION SUITE (TAB 3)
// =====================================================================
async function loadAndRenderBenchmarks() {
  try {
    const res = await fetch('/api/benchmarks/run', { method: 'POST' });
    const data = await res.json();
    if (data.status === 'success') {
      renderAccuracyTable(data.edge_masking.evaluation_metrics);
      renderAccuracyChart(data.edge_masking.evaluation_metrics);
      renderScalabilityTable(data.scalability);
      renderScalabilityChart(data.scalability);
      renderTestMatrix(data.test_matrix);
    }
  } catch (err) {
    console.error("Error executing benchmark suite:", err);
  }
}

function renderAccuracyTable(metrics) {
  const tbody = document.getElementById('benchmark-accuracy-tbody');
  tbody.innerHTML = '';

  metrics.forEach(m => {
    const isHybrid = m.model.includes('Hybrid');
    const tr = document.createElement('tr');
    tr.className = isHybrid ? "bg-brand-accent/10 border-l-2 border-brand-accent" : "hover:bg-slate-800/40";
    tr.innerHTML = `
      <td class="p-2.5 font-bold ${isHybrid ? 'text-brand-cyan' : 'text-white'}">${m.model}</td>
      <td class="p-2.5">${(m.precision_at_5 * 100).toFixed(1)}%</td>
      <td class="p-2.5">${(m.recall_at_5 * 100).toFixed(1)}%</td>
      <td class="p-2.5 font-bold ${isHybrid ? 'text-emerald-400' : 'text-slate-300'}">${m.f1_score.toFixed(3)}</td>
      <td class="p-2.5 font-bold ${isHybrid ? 'text-brand-cyan' : 'text-slate-400'}">${m.auc_roc.toFixed(3)}</td>
    `;
    tbody.appendChild(tr);
  });
}

function renderAccuracyChart(metrics) {
  const ctx = document.getElementById('accuracyChart');
  if (!ctx) return;

  if (STATE.charts.accuracy) {
    STATE.charts.accuracy.destroy();
  }

  const labels = metrics.map(m => m.model.split(' ')[0]);
  const f1Scores = metrics.map(m => m.f1_score);
  const precisions = metrics.map(m => m.precision_at_5);

  STATE.charts.accuracy = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: [
        {
          label: 'F1-Score',
          data: f1Scores,
          backgroundColor: '#06b6d4'
        },
        {
          label: 'Precision@5',
          data: precisions,
          backgroundColor: '#6366f1'
        }
      ]
    },
    options: {
      responsive: true,
      plugins: {
        legend: { labels: { color: '#94a3b8', font: { family: 'Plus Jakarta Sans', size: 10 } } }
      },
      scales: {
        x: { ticks: { color: '#94a3b8', font: { size: 10 } }, grid: { display: false } },
        y: { ticks: { color: '#94a3b8', font: { size: 10 } }, grid: { color: '#1e293b' }, min: 0, max: 1.0 }
      }
    }
  });
}

function renderScalabilityTable(scalability) {
  const tbody = document.getElementById('benchmark-scalability-tbody');
  tbody.innerHTML = '';

  scalability.forEach(s => {
    const tr = document.createElement('tr');
    tr.className = "hover:bg-slate-800/40 transition";
    tr.innerHTML = `
      <td class="p-2.5 font-bold text-white">N = ${s.nodes_count}</td>
      <td class="p-2.5 text-slate-400">E = ${s.edges_count}</td>
      <td class="p-2.5 text-cyan-400 font-bold">${s.kruskal_ms} ms</td>
      <td class="p-2.5 text-indigo-400 font-bold">${s.prim_ms} ms</td>
      <td class="p-2.5 text-emerald-400 font-bold">${s.kahns_ms} ms</td>
      <td class="p-2.5 text-amber-400 font-bold">${s.hybrid_link_pred_ms} ms</td>
    `;
    tbody.appendChild(tr);
  });
}

function renderScalabilityChart(scalability) {
  const ctx = document.getElementById('scalabilityChart');
  if (!ctx) return;

  if (STATE.charts.scalability) {
    STATE.charts.scalability.destroy();
  }

  const labels = scalability.map(s => `N=${s.nodes_count}`);

  STATE.charts.scalability = new Chart(ctx, {
    type: 'line',
    data: {
      labels: labels,
      datasets: [
        {
          label: "Kruskal's MST",
          data: scalability.map(s => s.kruskal_ms),
          borderColor: '#06b6d4',
          tension: 0.3
        },
        {
          label: "Prim's MST",
          data: scalability.map(s => s.prim_ms),
          borderColor: '#6366f1',
          tension: 0.3
        },
        {
          label: "Kahn's Sort",
          data: scalability.map(s => s.kahns_ms),
          borderColor: '#10b981',
          tension: 0.3
        }
      ]
    },
    options: {
      responsive: true,
      plugins: {
        legend: { labels: { color: '#94a3b8', font: { family: 'Plus Jakarta Sans', size: 10 } } }
      },
      scales: {
        x: { ticks: { color: '#94a3b8', font: { size: 10 } }, grid: { display: false } },
        y: { ticks: { color: '#94a3b8', font: { size: 10 } }, grid: { color: '#1e293b' } }
      }
    }
  });
}

function renderTestMatrix(matrix) {
  const tbody = document.getElementById('test-matrix-tbody');
  tbody.innerHTML = '';

  document.getElementById('test-summary-badge').innerText = `${matrix.passed}/${matrix.total_tests} Passed (${matrix.pass_rate_percentage}%)`;

  matrix.test_cases.forEach(tc => {
    const tr = document.createElement('tr');
    tr.className = "hover:bg-slate-800/40 transition";
    tr.innerHTML = `
      <td class="p-2.5 font-bold text-slate-400">${tc.id}</td>
      <td class="p-2.5 font-bold text-white">${tc.name}</td>
      <td class="p-2.5 text-brand-cyan">${tc.category}</td>
      <td class="p-2.5 text-slate-400 text-[11px]">${tc.input}</td>
      <td class="p-2.5 text-slate-300 text-[11px]">${tc.expected}</td>
      <td class="p-2.5 text-slate-400 text-[11px]">${tc.actual}</td>
      <td class="p-2.5">
        <span class="badge-pill bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
          <i class="fa-solid fa-check"></i> ${tc.status}
        </span>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

// =====================================================================
// 6. VIVA ACCORDION (TAB 4)
// =====================================================================
function renderVivaAccordion() {
  const container = document.getElementById('viva-accordion');
  if (!container) return;

  const vivaQuestions = [
    {
      q: "Q1. What is the fundamental difference between Kruskal's and Prim's algorithms in this social network application?",
      a: "Both algorithms compute the Minimum Spanning Tree (MST) representing the core social influence backbone. Kruskal's is an edge-centric greedy algorithm that sorts all edges by dissimilarity cost and uses a Disjoint Set Union (DSU with union by rank and path compression) to avoid cycles in O(E log E). Prim's is a vertex-centric algorithm that grows a connected tree from an arbitrary root node using a binary min-heap priority queue in O(E log V). In sparse social networks (E << V^2), Kruskal is generally faster, whereas Prim is ideal when starting from a designated community seed node."
    },
    {
      q: "Q2. Why do we invert interaction strengths to calculate MST costs?",
      a: "In social networks, high interaction strength represents high affinity and low relationship resistance. Since standard MST algorithms minimize the sum of edge weights, we define edge cost as 10.0 / interaction_strength (or 11 - strength). Minimizing this cost mathematically maximizes the overall social affinity across the spanning backbone."
    },
    {
      q: "Q3. How does Topological Sorting model academic mentorship hierarchies?",
      a: "Mentorship and skill prerequisites define a directed relationship where knowledge flows from mentor to mentee. For an acyclic hierarchy, a topological sort orders users such that if user A mentors user B, A appears before B. Kahn's algorithm resolves this by iteratively picking vertices with in-degree 0 (root mentors free of dependencies) and decrementing neighbors' in-degrees, producing stratified knowledge tiers in O(V + E)."
    },
    {
      q: "Q4. How are cycles detected and resolved in the mentorship graph?",
      a: "We implement 3-state Depth First Search (DFS) color coding: WHITE (unvisited), GRAY (visiting / recursion stack), and BLACK (finished). If a traversal encounters a GRAY node, a back-edge is detected, proving a cycle. In Kahn's algorithm, a cycle is proven if the total nodes in the topological order are fewer than V. In practice, cyclic peer learning is resolved by removing or re-labeling the feedback edge as mutual collaboration rather than hierarchical mentorship."
    },
    {
      q: "Q5. Why is the Adamic-Adar Index superior to Common Neighbors in link prediction?",
      a: "Common Neighbors simply counts |N(u) ∩ N(v)|, giving equal weight to every shared acquaintance. Adamic-Adar weights shared neighbors inversely proportional to the logarithm of their degree: Σ (1 / log(degree(z))). A shared neighbor who only has 2 friends indicates a much higher personal intimacy and likelihood of future connection than a shared 'celebrity' node connected to 500 people."
    },
    {
      q: "Q6. How does this system solve the Cold-Start Problem for new students?",
      a: "New students enter with degree = 0 (no friends or common neighbors). Topological metrics like Jaccard and Adamic-Adar produce zero. Our Hybrid AI Engine solves this by incorporating semantic profile cosine similarity on multi-hot encoded skill and interest vectors, along with department and academic year affinity. This guarantees relevant recommendations immediately upon profile creation without requiring existing friends."
    },
    {
      q: "Q7. What is the heuristic function used in the A* Social Path Finder?",
      a: "The pathfinder finds the warmest introduction route between unconnected users U and V. The evaluation function is f(n) = g(n) + h(n), where g(n) is the exact cumulative relationship resistance traversed so far, and h(n) = (1 - CosineSimilarity(n, V)) * scaling_factor. Because cosine distance satisfies the triangle inequality when scaled, h(n) is an admissible and consistent heuristic, guaranteeing optimal path discovery in CO2."
    },
    {
      q: "Q8. Explain the mathematical formula of Cosine Similarity on user profile vectors.",
      a: "Cosine Similarity measures the cosine of the angle between two multi-hot vectors A and B: Cos(A, B) = (A · B) / (||A|| * ||B||) = Σ(Ai * Bi) / (sqrt(Σ Ai^2) * sqrt(Σ Bi^2)). It normalizes for vector length, meaning students with 10 listed skills are fairly compared with students who only listed 3 skills, focusing strictly on orientation in skill space."
    },
    {
      q: "Q9. What are the time and space complexities of the entire system?",
      a: "MST (Kruskal): O(E log E) time, O(V + E) space. MST (Prim): O(E log V) time, O(V + E) space. Topological Sort (Kahn's): O(V + E) time, O(V + E) space. Link Prediction per candidate: O(degree(u) + degree(v) + |vocabulary|) ~ O(V) time. The overall system operates in sub-second latency for university-scale graphs."
    },
    {
      q: "Q10. How does this project directly satisfy Course Outcomes CO2, CO3, and CO5?",
      a: "CO2 (Graph Algorithms & Search): Implemented from scratch via Kruskal's/Prim's MST, Kahn's/DFS traversal, and A* social heuristic search. CO3 (Knowledge Representation): Represented via semantic multi-relational graphs, DAG dependency hierarchies, and cycle resolution rules. CO5 (AI Applications): Feature vector cosine similarity, Adamic-Adar heuristic link prediction, edge masking benchmarking, and explainable AI recommendation badges."
    }
  ];

  container.innerHTML = '';
  vivaQuestions.forEach((item, idx) => {
    const card = document.createElement('div');
    card.className = "border border-brand-border rounded-xl bg-slate-900/70 overflow-hidden";
    card.innerHTML = `
      <button class="w-full text-left p-3.5 flex items-center justify-between text-xs font-bold text-slate-200 hover:text-brand-cyan transition">
        <span>${item.q}</span>
        <i class="fa-solid fa-chevron-down text-slate-500 transition-transform"></i>
      </button>
      <div class="px-3.5 pb-3.5 text-xs text-slate-400 leading-relaxed hidden border-t border-brand-border/40 pt-2.5">
        ${item.a}
      </div>
    `;

    const btn = card.querySelector('button');
    const ans = card.querySelector('div');
    const icon = card.querySelector('i');

    btn.addEventListener('click', () => {
      const isHidden = ans.classList.contains('hidden');
      ans.classList.toggle('hidden');
      icon.style.transform = isHidden ? 'rotate(180deg)' : 'rotate(0deg)';
      btn.classList.toggle('text-brand-cyan', isHidden);
    });

    container.appendChild(card);
  });
}

// =====================================================================
// 7. EVENT LISTENERS & MODAL MANAGEMENT
// =====================================================================
function setupEventListeners() {
  document.getElementById('select-active-user').addEventListener('change', (e) => {
    selectUser(e.target.value);
  });

  document.getElementById('btn-fit-graph').addEventListener('click', () => {
    if (STATE.mainNetwork) STATE.mainNetwork.fit({ animation: true });
  });

  document.getElementById('btn-toggle-physics').addEventListener('click', () => {
    if (STATE.mainNetwork) {
      const current = STATE.mainNetwork.physics.physicsEnabled;
      STATE.mainNetwork.setOptions({ physics: { enabled: !current } });
      showToast(`Physics ${!current ? 'Enabled' : 'Disabled'}`);
    }
  });

  document.getElementById('btn-reset-graph').addEventListener('click', async () => {
    if (confirm("Reset network to default 28 academic profiles?")) {
      try {
        const res = await fetch('/api/graph/reset', { method: 'POST' });
        const data = await res.json();
        showToast(data.message);
        await loadGraphState();
        initMainNetwork();
        selectUser('u1');
      } catch (err) {
        showToast("Error resetting graph", "error");
      }
    }
  });

  document.getElementById('btn-run-kruskal').addEventListener('click', () => runMSTVisualization('kruskal'));
  document.getElementById('btn-run-prim').addEventListener('click', () => runMSTVisualization('prim'));
  document.getElementById('btn-topo-kahn').addEventListener('click', () => runTopologicalSort('kahns'));
  document.getElementById('btn-topo-dfs').addEventListener('click', () => runTopologicalSort('dfs'));
  document.getElementById('btn-run-all-benchmarks').addEventListener('click', async () => {
    showToast("Running evaluation suite...");
    await loadAndRenderBenchmarks();
    showToast("Benchmark suite complete!");
  });
}

function setupModal() {
  const modal = document.getElementById('modal-add-user');
  const btnOpen = document.getElementById('btn-quick-add-user');
  const btnClose = document.getElementById('btn-close-modal');
  const btnCancel = document.getElementById('btn-cancel-modal');
  const form = document.getElementById('form-add-user');

  const open = () => modal.classList.remove('hidden');
  const close = () => {
    modal.classList.add('hidden');
    form.reset();
  };

  btnOpen.addEventListener('click', open);
  btnClose.addEventListener('click', close);
  btnCancel.addEventListener('click', close);

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('input-name').value.trim();
    const dept = document.getElementById('input-dept').value;
    const year = document.getElementById('input-year').value;
    const skills = document.getElementById('input-skills').value.split(',').map(s => s.trim()).filter(Boolean);
    const interests = document.getElementById('input-interests').value.split(',').map(i => i.trim()).filter(Boolean);

    try {
      const res = await fetch('/api/graph/user/add', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, department: dept, year, skills, interests, role: "Student Member" })
      });
      const data = await res.json();
      if (data.status === 'success') {
        showToast(`Student ${name} added!`);
        close();
        await loadGraphState();
        initMainNetwork();
        selectUser(data.user.id);
      }
    } catch (err) {
      showToast("Error adding student", "error");
    }
  });
}
