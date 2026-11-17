/**
 * HUNG PHAT WMS - EXPANSION AI AGENT SERVER
 * High-performance, zero-dependency Node.js HTTP server.
 * Supports static file delivery, pipeline calculations, and AI chat endpoints.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 8080;
const HOST = process.env.HOST || '0.0.0.0';
const ROOT_DIR = __dirname;

// Load base data
let globalData = {};
try {
  const dataRaw = fs.readFileSync(path.join(ROOT_DIR, 'data.json'), 'utf8');
  globalData = JSON.parse(dataRaw);
  console.log('[DATA] Đã nạp thành công data.json với 4 địa bàn và cơ sở tri thức.');
} catch (err) {
  console.error('[ERROR] Không thể đọc data.json:', err.message);
}

// MIME types dictionary
const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.htm': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.txt': 'text/plain; charset=utf-8',
  '.webp': 'image/webp'
};

// Helper to set CORS headers
function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

// Helper to send JSON response
function sendJson(res, statusCode, data) {
  setCorsHeaders(res);
  res.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(data, null, 2));
}

// Pipeline evaluation logic
function runAgentPipeline(customWeights = {}) {
  const w_fit = customWeights.fit_score !== undefined ? Number(customWeights.fit_score) : 0.30;
  const w_support = customWeights.support_feasibility !== undefined ? Number(customWeights.support_feasibility) : 0.25;
  const w_market = customWeights.market_size !== undefined ? Number(customWeights.market_size) : 0.20;
  const w_lead = customWeights.lead_quality !== undefined ? Number(customWeights.lead_quality) : 0.15;
  const w_comp = customWeights.competition_pressure !== undefined ? Number(customWeights.competition_pressure) : 0.10;

  const now = new Date().toISOString().replace('T', ' ').slice(0, 19);
  const steps = [];

  // Bước 1
  steps.push({
    step: 1,
    name: 'Thu Thập & Chuẩn Hóa Dữ Liệu Đầu Vào',
    status: 'COMPLETED',
    summary: 'Đã thu nạp 4 hồ sơ địa bàn, 5 tài liệu thị trường, 5 hồ sơ đối thủ, 14 leads khách hàng và năng lực đội triển khai 5 người.',
    timestamp: now,
    details: [
      'Tài liệu thị trường: Gắn tag thời điểm và nguồn (Sở Công Thương, AVR, VCCI, VLA).',
      'Năng lực Hưng Phát: Đội triển khai 5 kỹ sư, phục vụ tối đa 1 đợt mở rộng với 2 địa bàn song song.',
      'Giới hạn on-site: Tối đa 2 lần/tháng cho địa bàn cách xa >300km; không thể hỗ trợ trực on-site 24/7.'
    ]
  });

  // Bước 2
  const harmonizedTerritories = (globalData.territories || []).map(t => {
    let cleanSize = 0;
    let dupDeduction = 0;
    let syncNote = '';
    let fitScore = 0;

    if (t.id === 'T1') {
      cleanSize = 227;
      dupDeduction = 18;
      syncNote = 'Đồng bộ về chuẩn Q2/2025. Loại bỏ 18 chuỗi trùng lặp giữa Sở Công Thương và AVR.';
      fitScore = 92;
    } else if (t.id === 'T2') {
      cleanSize = 160;
      dupDeduction = 160;
      syncNote = 'Phát hiện Tạp chí Logistics copy 100% từ VCCI Đà Nẵng. Loại bỏ 160 số liệu nhân đôi, giữ chuẩn 160 chuỗi.';
      fitScore = 88;
    } else if (t.id === 'T3') {
      cleanSize = 75;
      dupDeduction = 235;
      syncNote = 'Dữ liệu cũ (2023). Bóc tách 180 hộ cá thể không thuộc đối tượng WMS chuỗi, quy mô chuỗi thực tế chỉ còn ~75 đơn vị.';
      fitScore = 48;
    } else if (t.id === 'T4') {
      cleanSize = 55;
      dupDeduction = 130;
      syncNote = '70% doanh nghiệp là kho ngoại quan/container cảng biển. Chuỗi bán lẻ khớp mục tiêu chỉ có ~55 đơn vị.';
      fitScore = 52;
    }

    return {
      id: t.id,
      name: t.name,
      region: t.region,
      raw_reports: t.market_reports,
      data_issues: t.data_issues,
      clean_market_size: cleanSize,
      deduplication_removed: dupDeduction,
      sync_note: syncNote,
      fit_score: fitScore
    };
  });

  steps.push({
    step: 2,
    name: 'Xử Lý & Chuẩn Hóa Thông Tin',
    status: 'COMPLETED',
    summary: 'Đã khử trùng lặp dữ liệu, đồng bộ hóa kỳ thống kê về chuẩn 2025 và chấm điểm độ khớp tính năng WMS.',
    timestamp: now,
    details: [
      'Phát hiện & loại bỏ 160 số liệu lặp tại Đà Nẵng (do 2 báo cáo dẫn cùng 1 nguồn).',
      'Loại bỏ 18 bản ghi trùng tại Bình Dương và bóc tách 180 hộ cá thể sai đối tượng tại Cần Thơ.',
      'Chấm độ khớp WMS: Bình Dương (92%), Đà Nẵng (88%), Hải Phòng (52%), Cần Thơ (48%).'
    ]
  });

  // Bước 3
  const evaluatedTerritories = harmonizedTerritories.map(ht => {
    const orig = (globalData.territories || []).find(x => x.id === ht.id) || {};
    let supportScore = 0;
    let supportFeasibility = '';
    const qualifiedLeads = [];
    const disqualifiedLeads = [];

    const leads = orig.leads || [];

    if (ht.id === 'T1') {
      supportScore = 95;
      supportFeasibility = 'RẤT CAO: Cách HQ 45km (1.2h). Đội 5 kỹ sư di chuyển linh hoạt trong ngày, đáp ứng 100% SLA.';
      leads.forEach(l => {
        if (l.id !== 'L04') qualifiedLeads.push(l);
        else disqualifiedLeads.push(l);
      });
    } else if (ht.id === 'T2') {
      supportScore = 82;
      supportFeasibility = 'KHẢ THI: Có chuyến bay thẳng từ TP.HCM (1.5h). Phù hợp đào tạo tập trung và on-site 2 đợt/tháng.';
      leads.forEach(l => {
        if (l.id !== 'L08') qualifiedLeads.push(l);
        else disqualifiedLeads.push(l);
      });
    } else if (ht.id === 'T3') {
      supportScore = 35;
      supportFeasibility = 'RỦI RO CAO (QUÁ TẢI): Khách hàng yêu cầu trực kỹ thuật 24/7 on-site trong 3 tuần đầu. 1 team 5 người sẽ kiệt sức, phá vỡ SLA.';
      leads.forEach(l => disqualifiedLeads.push(l));
    } else if (ht.id === 'T4') {
      supportScore = 45;
      supportFeasibility = 'TRUNG BÌNH THẤP: Cách 1750km, chi phí di chuyển cao, quy mô triển khai đòi hỏi đội ngũ >= 10 người.';
      leads.forEach(l => {
        if (l.id === 'L12') qualifiedLeads.push(l);
        else disqualifiedLeads.push(l);
      });
    }

    const marketScore = Math.min(100, Math.round((ht.clean_market_size / 230) * 100));
    const leadScore = Math.round((qualifiedLeads.length / Math.max(1, leads.length)) * 100);

    let compScore = 50;
    if (ht.id === 'T1') compScore = 75;
    else if (ht.id === 'T2') compScore = 85;
    else if (ht.id === 'T3') compScore = 40;
    else if (ht.id === 'T4') compScore = 30;

    const totalScore = Number((
      (ht.fit_score * w_fit) +
      (supportScore * w_support) +
      (marketScore * w_market) +
      (leadScore * w_lead) +
      (compScore * w_comp)
    ).toFixed(1));

    return {
      id: ht.id,
      name: ht.name,
      region: ht.region,
      clean_market_size: ht.clean_market_size,
      sync_note: ht.sync_note,
      fit_score: ht.fit_score,
      support_score: supportScore,
      support_feasibility: supportFeasibility,
      market_score: marketScore,
      lead_score: leadScore,
      comp_score: compScore,
      total_score: totalScore,
      qualified_leads: qualifiedLeads,
      disqualified_leads: disqualifiedLeads
    };
  });

  steps.push({
    step: 3,
    name: 'Đánh Giá Khả Năng Đáp Ứng & Sàng Lọc Khách Hàng Tiềm Năng',
    status: 'COMPLETED',
    summary: 'Đối soát giới hạn 01 đội triển khai 5 người với yêu cầu on-site thực tế. Lọc bỏ các leads lệch phân khúc kho lạnh sâu và yêu cầu trực 24/7.',
    timestamp: now,
    details: [
      'Bình Dương: 3/4 leads đạt chuẩn (loại 01 chuỗi kho ngoại quan).',
      'Đà Nẵng: 3/4 leads đạt chuẩn (loại 01 chuỗi nhà thuốc tư nhân không thuộc phân khúc WMS chuỗi).',
      'Cần Thơ: Loại toàn bộ leads do yêu cầu on-site 24/7 và giải pháp kho lạnh sâu âm 25°C.',
      'Hải Phòng: Chỉ giữ 01 lead bán lẻ nội địa; loại các đơn vị cảng biển container.'
    ]
  });

  // Sort ranked territories descending
  const ranked = [...evaluatedTerritories].sort((a, b) => b.total_score - a.total_score);
  ranked.forEach((r, idx) => { r.rank = idx + 1; });

  const selected = ranked.slice(0, 2);
  const excluded = ranked.slice(2);

  steps.push({
    step: 4,
    name: 'Tổng Hợp Điểm Số, Xếp Hạng & Ra Quyết Định',
    status: 'COMPLETED',
    summary: `Khuyến nghị chính thức: Chọn ${selected.map(s => s.name).join(' và ')}. Loại trừ ${excluded.map(e => e.name).join(' và ')}.`,
    timestamp: now,
    details: [
      `Hạng 1: ${ranked[0].name} - Điểm tổng hợp: ${ranked[0].total_score}/100.`,
      `Hạng 2: ${ranked[1].name} - Điểm tổng hợp: ${ranked[1].total_score}/100.`,
      `Loại: ${ranked[2].name} (${ranked[2].total_score}) & ${ranked[3].name} (${ranked[3].total_score}) do rủi ro vượt ngưỡng hỗ trợ hoặc biên lợi nhuận thấp.`
    ]
  });

  return {
    run_id: 'HP-' + Date.now().toString(36).toUpperCase(),
    timestamp: now,
    weights_used: {
      fit_score: w_fit,
      support_feasibility: w_support,
      market_size: w_market,
      lead_quality: w_lead,
      competition_pressure: w_comp
    },
    steps,
    ranked_territories: ranked,
    selected,
    excluded,
    recommendation_justification: {
      why_top2: 'Địa bàn A (Bình Dương) và Địa bàn B (Đà Nẵng) đạt điểm vượt trội về độ khớp giải pháp WMS (>88%) và khả năng hỗ trợ tại chỗ hoàn toàn nằm trong tầm kiểm soát của đội triển khai 5 người. Đảm bảo tỷ lệ chuyển đổi cao và tối ưu chi phí vận hành.',
      why_excluded_can_tho: 'Địa bàn C (Cần Thơ) quy mô báo cáo bị thổi phồng bởi hộ kinh doanh cá thể; nhu cầu kho lạnh sâu lệch khỏi danh mục WMS; và yêu cầu kỹ sư trực 24/7 on-site vượt quá khả năng đội ngũ Hưng Phát.',
      why_excluded_hai_phong: 'Địa bàn D (Hải Phòng) thị trường chủ yếu là kho logistics cảng biển (lệch WMS bán lẻ), đối thủ địa phương đang phá giá 40%, chi phí hỗ trợ xa xôi không hiệu quả cho đợt mở rộng duy nhất này.'
    }
  };
}

// AI Chatbot Knowledge Base
function generateChatResponse(userMessage) {
  const msg = (userMessage || '').toLowerCase();
  const now = new Date().toISOString().replace('T', ' ').slice(0, 19);

  let reply = '';

  if (msg.includes('cần thơ') || msg.includes('can tho') || msg.includes('tại sao loại')) {
    reply = `### Phân tích AI Agent: Lý do loại trừ Địa bàn C (Cần Thơ & ĐBSCL)

AI Agent đã thực hiện kiểm tra chéo và phát hiện 3 điểm 'báo động đỏ' sau:

1. **Số liệu thị trường bị 'thổi phồng' và lệch kỳ**: Báo cáo ban đầu ghi 310 đơn vị (số liệu cũ 2023). Sau khi đối soát, phát hiện có tới 180 hộ kinh doanh đơn lẻ / vựa gạo không có nhu cầu WMS chuỗi. Quy mô chuỗi thực tế chỉ còn ~75 đơn vị.
2. **Lệch giải pháp cốt lõi**: Khách hàng tại Cần Thơ chủ yếu yêu cầu quản lý kho lạnh âm sâu chuyên biệt (< -25°C) cho thủy hải sản và nông sản xuất khẩu — đây là giới hạn kỹ thuật của WMS Hưng Phát hiện tại.
3. **Vượt ngưỡng hỗ trợ tại chỗ (On-site Overload)**: Khách hàng lớn (như Chuỗi Nông sản Mekong) đòi hỏi kỹ sư trực on-site 24/7 trong 3 tuần đầu. Với duy nhất 1 đội triển khai 5 người, việc này sẽ làm tê liệt toàn bộ hoạt động hỗ trợ khách hàng hiện tại của Hưng Phát.

Do đó, việc loại trừ Cần Thơ là quyết định bắt buộc để bảo toàn chất lượng dịch vụ và nguồn lực.`;
  } else if (msg.includes('đà nẵng') || msg.includes('da nang') || msg.includes('rủi ro')) {
    reply = `### Phân tích AI Agent: Đánh giá cơ hội & Rủi ro tại Địa bàn B (Đà Nẵng)

**1. Cơ hội chiến lược:**
- Thị trường tăng trưởng mạnh 22%/năm về chuỗi bán lẻ du lịch, quà tặng, thời trang.
- Đối thủ tại chỗ chủ yếu là phần mềm Desktop cũ kỹ, thị trường rất 'khát' giải pháp Cloud WMS hiện đại.
- Độ khớp tính năng đạt **88%** (Barcode 2D, điều chuyển đa chi nhánh, cross-docking).

**2. Điểm cần lưu ý đã được Agent làm sạch:**
- Nhân viên ban đầu cộng gộp 2 báo cáo thành 320 chuỗi. Agent phát hiện Tạp chí Logistics sao chép 100% từ VCCI Đà Nẵng, đã chuẩn hóa về đúng **160 chuỗi thực tế**.

**3. Phương án ứng phó năng lực triển khai:**
- Đà Nẵng cách 850km nhưng có đường bay thẳng (1.5h). Đội 5 người áp dụng mô hình: Đào tạo online 70% + Cử 2 kỹ sư on-site 3 ngày trong tuần Go-live. Đảm bảo đúng SLA mà không gây quá tải.`;
  } else if (msg.includes('hải phòng') || msg.includes('hai phong') || msg.includes('ban giám đốc ép')) {
    reply = `### Kịch bản phản biện Ban Giám Đốc nếu bị yêu cầu chọn Hải Phòng:

Trưởng phòng Kinh doanh có thể trình bày các luận cứ kiểm định sau:

1. **Thị trường không khớp phân khúc mục tiêu**: Báo cáo ghi 185 doanh nghiệp nhưng có tới 70% là kho logistics cảng biển container và kho ngoại quan hải quan. Phân khúc chuỗi bán lẻ thuần túy chỉ có ~55 đơn vị.
2. **Cuộc chiến giá khốc liệt**: Đối thủ Phương Bắc WMS đang phá giá 40%, cùng các công ty cảng độc quyền trợ giá hệ sinh thái. Hưng Phát bước vào sẽ bị cuốn vào cạnh tranh giá, biên lợi nhuận thấp.
3. **Chi phí và cự ly hỗ trợ**: Cách HQ 1.750km, nếu xảy ra sự cố cần hỗ trợ tại chỗ, chi phí vé máy bay và thời gian di chuyển sẽ ăn mòn toàn bộ doanh thu hợp đồng.
4. **Kiến nghị với BGĐ**: Chỉ nên mở rộng Hải Phòng ở đợt sau khi Hưng Phát thành lập chi nhánh miền Bắc và bổ sung module WMS Cảng biển.`;
  } else if (msg.includes('tuyển thêm') || msg.includes('nhân sự') || msg.includes('thêm kỹ sư')) {
    reply = `### Mô phỏng tình huống (What-If Analysis): Tuyển thêm 3 kỹ sư triển khai

Nếu Ban Giám đốc phê duyệt tuyển thêm 3 kỹ sư (nâng đội ngũ lên 8 người):
- **Khả năng phục vụ**: Có thể mở rộng đồng thời 3 địa bàn thay vì 2.
- **Tác động đến Cần Thơ**: Vẫn **KHÔNG NÊN** chọn, vì rào cản chính ở Cần Thơ là **độ lệch tính năng kho lạnh âm sâu**, không chỉ đơn thuần là thiếu người.
- **Tác động đến Hải Phòng**: Có thể cân nhắc đưa vào diện dự phòng nếu tuyển được kỹ sư am hiểu thị trường miền Bắc.
- **Khuyến nghị tối ưu**: Dù có thêm 3 nhân sự, Top 2 vẫn phải là **Bình Dương & Đà Nẵng** để đảm bảo tỷ lệ thành công 100% trước khi dàn trải lực lượng.`;
  } else if (msg.includes('làm sạch') || msg.includes('dữ liệu') || msg.includes('trùng lặp')) {
    reply = `### Kết quả kiểm định & làm sạch dữ liệu đầu vào:

- **Đà Nẵng**: Loại bỏ 160 số liệu sao chép trùng lặp do Tạp chí Logistics copy 100% từ VCCI Đà Nẵng.
- **Bình Dương**: Loại bỏ 18 bản ghi trùng lặp giữa Sở Công Thương và Hiệp hội AVR.
- **Cần Thơ**: Bóc tách 180 hộ kinh doanh cá thể sai đối tượng WMS chuỗi và chiết khấu số liệu cũ 2023.
- **Chuẩn hóa**: Toàn bộ dữ liệu được quy về mốc chuẩn hóa Q2/2025.`;
  } else {
    reply = `Xin chào Trưởng phòng! Tôi là AI Agent Hỗ trợ Quyết định Mở rộng Thị trường của Công ty Hưng Phát.

Dựa trên gói dữ liệu đã chuẩn hóa và 10 bước của quy trình kiểm toán:
- **Đề xuất tối ưu**: Lựa chọn **Địa bàn A (Bình Dương)** và **Địa bàn B (Đà Nẵng)** để tiến hành khảo sát khách hàng.
- **Đã sàng lọc**: Khử 178 bản ghi trùng lặp/ảo, loại bỏ 2 địa bàn có rủi ro vượt quá năng lực hỗ trợ tại chỗ (Cần Thơ) và cạnh tranh phá giá (Hải Phòng).

Bạn có thể hỏi tôi về:
1. *'Tại sao loại Cần Thơ dù khách hàng rất quan tâm?'*
2. *'Đà Nẵng có rủi ro gì và phương án giải quyết?'*
3. *'Cách phản biện nếu Ban Giám đốc muốn mở Hải Phòng?'*
4. *'Tác động nếu tuyển thêm kỹ sư triển khai?'*`;
  }

  return {
    reply,
    timestamp: now
  };
}

// Request dispatcher
const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const method = req.method;

  // Handle CORS Preflight
  if (method === 'OPTIONS') {
    setCorsHeaders(res);
    res.writeHead(200);
    res.end();
    return;
  }

  // API 1: GET /api/data
  if (pathname === '/api/data' && method === 'GET') {
    sendJson(res, 200, globalData);
    return;
  }

  // API 2: POST /api/run-pipeline
  if (pathname === '/api/run-pipeline' && method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let customWeights = {};
      try {
        if (body) {
          const parsed = JSON.parse(body);
          customWeights = parsed.weights || parsed;
        }
      } catch (e) {}

      const result = runAgentPipeline(customWeights);
      sendJson(res, 200, result);
    });
    return;
  }

  // API 3: POST /api/chat
  if (pathname === '/api/chat' && method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let message = '';
      try {
        if (body) {
          const parsed = JSON.parse(body);
          message = parsed.message || '';
        }
      } catch (e) {}

      const chatRes = generateChatResponse(message);
      sendJson(res, 200, chatRes);
    });
    return;
  }

  // API 4: Health check /api/health
  if (pathname === '/api/health' && method === 'GET') {
    sendJson(res, 200, { status: 'healthy', uptime: process.uptime(), time: new Date() });
    return;
  }

  // Static file delivery
  if (method === 'GET') {
    let safePath = pathname === '/' ? '/index.html' : pathname;
    // Security check against directory traversal
    safePath = path.normalize(safePath).replace(/^(\.\.[\/\\])+/, '');
    const filePath = path.join(ROOT_DIR, safePath);

    fs.stat(filePath, (err, stats) => {
      if (err || !stats.isFile()) {
        // Fallback to index.html for Single Page App routing
        const indexPath = path.join(ROOT_DIR, 'index.html');
        fs.readFile(indexPath, (readErr, content) => {
          if (readErr) {
            res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end('404 Not Found');
          } else {
            setCorsHeaders(res);
            res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
            res.end(content);
          }
        });
        return;
      }

      const ext = path.extname(filePath).toLowerCase();
      const contentType = MIME_TYPES[ext] || 'application/octet-stream';

      fs.readFile(filePath, (readErr, content) => {
        if (readErr) {
          res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
          res.end('500 Internal Server Error');
          return;
        }

        setCorsHeaders(res);
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(content);
      });
    });
    return;
  }

  // Fallthrough 405 Method Not Allowed
  res.writeHead(405, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end('Method Not Allowed');
});

server.listen(PORT, HOST, () => {
  console.log('==========================================================');
  console.log(`[HUNG PHAT WMS] Server đã sẵn sàng triển khai!`);
  console.log(`URL cục bộ: http://localhost:${PORT}`);
  console.log(`Cổng lắng nghe: ${PORT} (Mặc định hoặc qua process.env.PORT)`);
  console.log(`Thư mục dự án: ${ROOT_DIR}`);
  console.log('==========================================================');
});
