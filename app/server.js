const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Environment info
const startTime = new Date();
const hostname = require('os').hostname();

// Routes
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Azure Container Apps Demo</title>
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          background: linear-gradient(135deg, #0078d4 0%, #00bcf2 50%, #50e6ff 100%);
          background-size: 400% 400%;
          min-height: 100vh;
          padding: 20px;
          animation: gradientShift 15s ease infinite;
        }
        @keyframes gradientShift {
          0% { background-position: 0% 50%; }
          50% { background-position: 100% 50%; }
          100% { background-position: 0% 50%; }
        }
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }
        @keyframes pulse {
          0%, 100% { transform: scale(1); }
          50% { transform: scale(1.05); }
        }
        .container {
          max-width: 1200px;
          margin: 0 auto;
          background: rgba(255, 255, 255, 0.95);
          border-radius: 20px;
          padding: 40px;
          box-shadow: 0 20px 60px rgba(0,0,0,0.3);
          backdrop-filter: blur(10px);
          animation: fadeIn 0.6s ease;
        }
        .header {
          text-align: center;
          margin-bottom: 40px;
        }
        h1 {
          color: #0078d4;
          font-size: 3em;
          margin-bottom: 10px;
          background: linear-gradient(135deg, #0078d4, #00bcf2);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          animation: pulse 2s ease infinite;
        }
        .status-badge {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          padding: 10px 20px;
          background: linear-gradient(135deg, #4caf50, #8bc34a);
          color: white;
          border-radius: 30px;
          font-weight: bold;
          box-shadow: 0 4px 15px rgba(76,175,80,0.4);
        }
        .pulse-dot {
          width: 10px;
          height: 10px;
          background: white;
          border-radius: 50%;
          animation: pulse 1.5s ease infinite;
        }
        .info-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
          gap: 20px;
          margin: 30px 0;
        }
        .info-card {
          background: linear-gradient(135deg, rgba(255,255,255,0.9), rgba(248,249,250,0.95));
          padding: 25px;
          border-radius: 20px;
          border: 1px solid rgba(0,120,212,0.2);
          box-shadow: 0 8px 32px rgba(0,120,212,0.15);
          backdrop-filter: blur(10px);
          transition: all 0.3s ease;
        }
        .info-card:hover {
          transform: translateY(-8px) scale(1.02);
          box-shadow: 0 12px 40px rgba(0,120,212,0.25);
          border-color: rgba(0,120,212,0.4);
        }
        .info-card h3 {
          color: #0078d4;
          margin-bottom: 15px;
          display: flex;
          align-items: center;
          gap: 10px;
          font-size: 1.3em;
        }
        .info-item {
          margin: 12px 0;
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          padding: 12px;
          background: linear-gradient(135deg, #f8f9fa, #ffffff);
          border-radius: 8px;
          gap: 15px;
          transition: transform 0.2s ease;
        }
        .info-item:hover {
          transform: translateX(5px);
          box-shadow: -3px 0 0 #0078d4;
        }
        .label {
          font-weight: 600;
          color: #555;
          min-width: 140px;
          font-size: 0.9em;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }
        .value {
          color: #0078d4;
          font-family: 'Courier New', monospace;
          background: linear-gradient(135deg, #e3f2fd, #f0f7ff);
          padding: 6px 12px;
          border-radius: 6px;
          flex: 1;
          word-break: break-all;
          font-size: 0.95em;
          border-left: 3px solid #0078d4;
          box-shadow: 0 2px 4px rgba(0,120,212,0.1);
        }
        .features {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: 20px;
          margin: 30px 0;
        }
        .feature {
          background: linear-gradient(135deg, #e3f2fd, #fff);
          padding: 20px;
          border-radius: 15px;
          border-top: 4px solid #0078d4;
          transition: all 0.3s ease;
          animation: fadeIn 0.6s ease backwards;
        }
        .feature:nth-child(1) { animation-delay: 0.1s; }
        .feature:nth-child(2) { animation-delay: 0.2s; }
        .feature:nth-child(3) { animation-delay: 0.3s; }
        .feature:nth-child(4) { animation-delay: 0.4s; }
        .feature:nth-child(5) { animation-delay: 0.5s; }
        .feature:nth-child(6) { animation-delay: 0.6s; }
        .feature:nth-child(7) { animation-delay: 0.7s; }
        .feature:nth-child(8) { animation-delay: 0.8s; }
        .feature:hover {
          transform: scale(1.05);
          box-shadow: 0 8px 20px rgba(0,120,212,0.3);
        }
        .feature-icon {
          font-size: 2.5em;
          margin-bottom: 10px;
        }
        .feature h3 {
          color: #0078d4;
          margin-bottom: 10px;
          font-size: 1.1em;
        }
        .feature p {
          color: #666;
          font-size: 0.95em;
          line-height: 1.5;
        }
        .api-section {
          background: #263238;
          color: white;
          padding: 30px;
          border-radius: 15px;
          margin: 30px 0;
        }
        .api-section h2 {
          color: #00bcf2;
          margin-bottom: 20px;
        }
        .endpoint {
          background: #37474f;
          padding: 15px;
          margin: 10px 0;
          border-radius: 8px;
          display: flex;
          justify-content: space-between;
          align-items: center;
          transition: background 0.3s ease;
        }
        .endpoint:hover {
          background: #455a64;
        }
        .method {
          background: #4caf50;
          padding: 5px 15px;
          border-radius: 5px;
          font-weight: bold;
          font-family: monospace;
        }
        .endpoint-path {
          font-family: 'Courier New', monospace;
          color: #ffeb3b;
        }
        .footer {
          text-align: center;
          margin-top: 40px;
          padding-top: 30px;
          border-top: 2px solid #e0e0e0;
          color: #999;
        }
        .footer p {
          font-size: 0.9em;
        }
        #uptime {
          font-weight: bold;
          color: #0078d4;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🚀 Azure Container Apps</h1>
          <p style="color: #666; margin: 10px 0 20px 0; font-size: 1.2em;">Production-Ready Cloud Native Demo</p>
          <div class="status-badge">
            <div class="pulse-dot"></div>
            <span>ONLINE & HEALTHY</span>
          </div>
        </div>

        <div class="info-grid">
          <div class="info-card">
            <h3>🖥️ Container Details</h3>
            <div class="info-item">
              <span class="label">Hostname</span>
              <span class="value">${hostname}</span>
            </div>
            <div class="info-item">
              <span class="label">Started</span>
              <span class="value">${new Date(startTime).toLocaleString()}</span>
            </div>
            <div class="info-item">
              <span class="label">Live Uptime</span>
              <span class="value" id="uptime">${Math.floor((Date.now() - startTime) / 1000)}s</span>
            </div>
            <div class="info-item">
              <span class="label">Listen Port</span>
              <span class="value">${port}</span>
            </div>
          </div>

          <div class="info-card">
            <h3>⚙️ Runtime Environment</h3>
            <div class="info-item">
              <span class="label">Node Version</span>
              <span class="value">${process.version}</span>
            </div>
            <div class="info-item">
              <span class="label">Platform</span>
              <span class="value">${process.platform}</span>
            </div>
            <div class="info-item">
              <span class="label">Architecture</span>
              <span class="value">${process.arch}</span>
            </div>
            <div class="info-item">
              <span class="label">Memory (RSS)</span>
              <span class="value">${Math.round(process.memoryUsage().rss / 1024 / 1024)}MB</span>
            </div>
          </div>

          <div class="info-card">
            <h3>🌐 Request Headers</h3>
            <div class="info-item">
              <span class="label">X-Forwarded-For</span>
              <span class="value">${req.headers['x-forwarded-for'] || 'N/A'}</span>
            </div>
            <div class="info-item">
              <span class="label">X-Forwarded-Proto</span>
              <span class="value">${req.headers['x-forwarded-proto'] || 'N/A'}</span>
            </div>
            <div class="info-item">
              <span class="label">X-Original-URL</span>
              <span class="value">${req.headers['x-original-url'] || req.url}</span>
            </div>
            <div class="info-item">
              <span class="label">X-Original-Host</span>
              <span class="value">${req.headers['x-original-host'] || req.headers.host}</span>
            </div>
            <div class="info-item">
              <span class="label">User-Agent</span>
              <span class="value" style="font-size: 0.85em;">${req.headers['user-agent']?.substring(0, 80) || 'N/A'}${req.headers['user-agent']?.length > 80 ? '...' : ''}</span>
            </div>
          </div>
        </div>

        <div class="api-section">
          <h2>📡 API Endpoints</h2>
          <div class="endpoint">
            <div>
              <span class="method">GET</span>
              <span class="endpoint-path">/</span>
            </div>
            <span>This interactive dashboard</span>
          </div>
          <div class="endpoint">
            <div>
              <span class="method">GET</span>
              <span class="endpoint-path">/health</span>
            </div>
            <span>Health check probe (JSON)</span>
          </div>
          <div class="endpoint">
            <div>
              <span class="method">GET</span>
              <span class="endpoint-path">/api/info</span>
            </div>
            <span>Detailed container metadata (JSON)</span>
          </div>
        </div>

        <div class="footer">
          <p><strong>Customer Demo Project</strong></p>
          <p>Azure Container Apps with BYO VNET • Managed Identity • Private ACR</p>
          <p style="margin-top: 10px; font-size: 0.85em;">West US 3 Region • Resource Group: rg-containerapp-demo</p>
        </div>
      </div>

      <script>
        // Live uptime counter
        const startTime = ${startTime.getTime()};
        setInterval(() => {
          const uptimeSeconds = Math.floor((Date.now() - startTime) / 1000);
          const hours = Math.floor(uptimeSeconds / 3600);
          const minutes = Math.floor((uptimeSeconds % 3600) / 60);
          const seconds = uptimeSeconds % 60;
          document.getElementById('uptime').textContent = 
            hours > 0 ? \`\${hours}h \${minutes}m \${seconds}s\` : 
            minutes > 0 ? \`\${minutes}m \${seconds}s\` : \`\${seconds}s\`;
        }, 1000);
      </script>
    </body>
    </html>
  `);
});app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

app.get('/api/info', (req, res) => {
  res.json({
    hostname: hostname,
    startTime: startTime,
    uptime: process.uptime(),
    port: port,
    nodeVersion: process.version,
    platform: process.platform,
    arch: process.arch,
    memory: {
      rss: `${Math.round(process.memoryUsage().rss / 1024 / 1024)}MB`,
      heapTotal: `${Math.round(process.memoryUsage().heapTotal / 1024 / 1024)}MB`,
      heapUsed: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).send('404 - Not Found');
});

// Start server
app.listen(port, () => {
  console.log(`✓ Demo webapp listening on port ${port}`);
  console.log(`✓ Hostname: ${hostname}`);
  console.log(`✓ Started at: ${startTime.toISOString()}`);
});
