param(
    [int]$Port = 8080
)

$Host.UI.RawUI.WindowTitle = "Hung Phat WMS - Expansion AI Agent Server (Port $Port)"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$Listener = New-Object System.Net.HttpListener
$Prefix = "http://localhost:$Port/"
$Listener.Prefixes.Add($Prefix)

try {
    $Listener.Start()
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host " [HUNG PHAT WMS] AI Agent Server dang khoi chay!" -ForegroundColor Cyan
    Write-Host " URL: $Prefix" -ForegroundColor Yellow
    Write-Host " Thu muc goc: $ScriptDir" -ForegroundColor Gray
    Write-Host " Nhan Ctrl+C de dung server." -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Green
} catch {
    Write-Error "Khong the khoi dong HttpListener tren cong $Port. Loi: $_"
    exit 1
}

# Load base data
$DataPath = Join-Path $ScriptDir "data.json"
$GlobalData = Get-Content -Path $DataPath -Raw -Encoding UTF8 | ConvertFrom-Json

function Get-MimeType($extension) {
    switch ($extension.ToLower()) {
        ".html" { return "text/html; charset=utf-8" }
        ".htm"  { return "text/html; charset=utf-8" }
        ".css"  { return "text/css; charset=utf-8" }
        ".js"   { return "application/javascript; charset=utf-8" }
        ".json" { return "application/json; charset=utf-8" }
        ".png"  { return "image/png" }
        ".jpg"  { return "image/jpeg" }
        ".jpeg" { return "image/jpeg" }
        ".svg"  { return "image/svg+xml" }
        ".ico"  { return "image/x-icon" }
        default { return "application/octet-stream" }
    }
}

function Run-AgentPipeline($customWeights) {
    # Default weights if not provided
    $w_fit = 0.30
    $w_support = 0.25
    $w_market = 0.20
    $w_lead = 0.15
    $w_comp = 0.10

    if ($customWeights) {
        if ($customWeights.fit_score) { $w_fit = [double]$customWeights.fit_score }
        if ($customWeights.support_feasibility) { $w_support = [double]$customWeights.support_feasibility }
        if ($customWeights.market_size) { $w_market = [double]$customWeights.market_size }
        if ($customWeights.lead_quality) { $w_lead = [double]$customWeights.lead_quality }
        if ($customWeights.competition_pressure) { $w_comp = [double]$customWeights.competition_pressure }
    }

    $auditLog = @()
    $steps = @()

    # Bước 1: Thu thập & Chuẩn hóa đầu vào
    $steps += @{
        step = 1
        name = "Thu Thập & Chuẩn Hóa Dữ Liệu Đầu Vào"
        status = "COMPLETED"
        summary = "Đã thu nạp 4 hồ sơ địa bàn, 5 tài liệu thị trường, 5 hồ sơ đối thủ, 14 leads khách hàng và năng lực đội triển khai 5 người."
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        details = @(
            "Tài liệu thị trường: Gắn tag thời điểm và nguồn (Sở Công Thương, AVR, VCCI, VLA).",
            "Năng lực Hưng Phát: Đội triển khai 5 kỹ sư, phục vụ tối đa 1 đợt mở rộng với 2 địa bàn song song.",
            "Giới hạn on-site: Tối đa 2 lần/tháng cho địa bàn cách xa >300km; không thể hỗ trợ trực on-site 24/7."
        )
    }

    # Bước 2: Xử lý & Chuẩn hóa thông tin
    $harmonizedTerritories = @()
    foreach ($t in $GlobalData.territories) {
        $cleanSize = 0
        $dupDeduction = 0
        $syncNote = ""
        $fitScore = 0

        if ($t.id -eq "T1") { # Bình Dương
            $cleanSize = 227 # 245 - 18 trùng
            $dupDeduction = 18
            $syncNote = "Đồng bộ về chuẩn Q2/2025. Loại bỏ 18 chuỗi trùng lặp giữa Sở Công Thương và AVR."
            $fitScore = 92
        } elseif ($t.id -eq "T2") { # Đà Nẵng
            $cleanSize = 160 # Loại 160 lặp từ Tạp chí logistics
            $dupDeduction = 160
            $syncNote = "Phát hiện Tạp chí Logistics copy 100% từ VCCI Đà Nẵng. Loại bỏ 160 số liệu nhân đôi, giữ chuẩn 160 chuỗi."
            $fitScore = 88
        } elseif ($t.id -eq "T3") { # Cần Thơ
            $cleanSize = 75 # Bóc tách 180 hộ cá thể và chiết khấu số liệu cũ 2023
            $dupDeduction = 235
            $syncNote = "Dữ liệu cũ (2023). Bóc tách 180 hộ cá thể không thuộc đối tượng WMS chuỗi, quy mô chuỗi thực tế chỉ còn ~75 đơn vị."
            $fitScore = 48 # Nhu cầu nông sản đông lạnh lệch tính năng WMS Hưng Phát
        } elseif ($t.id -eq "T4") { # Hải Phòng
            $cleanSize = 55 # 30% bán lẻ thuần túy trong 185
            $dupDeduction = 130
            $syncNote = "70% doanh nghiệp là kho ngoại quan/container cảng biển. Chuỗi bán lẻ khớp mục tiêu chỉ có ~55 đơn vị."
            $fitScore = 52 # Khách đòi hỏi tích hợp cảng biển & kho ngoại quan
        }

        $harmonizedTerritories += @{
            id = $t.id
            name = $t.name
            region = $t.region
            raw_reports = $t.market_reports
            data_issues = $t.data_issues
            clean_market_size = $cleanSize
            deduplication_removed = $dupDeduction
            sync_note = $syncNote
            fit_score = $fitScore
        }
    }

    $steps += @{
        step = 2
        name = "Xử Lý & Chuẩn Hóa Thông Tin"
        status = "COMPLETED"
        summary = "Đã khử trùng lặp dữ liệu, đồng bộ hóa kỳ thống kê về chuẩn 2025 và chấm điểm độ khớp tính năng WMS."
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        details = @(
            "Phát hiện & loại bỏ 160 số liệu lặp tại Đà Nẵng (do 2 báo cáo dẫn cùng 1 nguồn).",
            "Loại bỏ 18 bản ghi trùng tại Bình Dương và bóc tách 180 hộ cá thể sai đối tượng tại Cần Thơ.",
            "Chấm độ khớp WMS: Bình Dương (92%), Đà Nẵng (88%), Hải Phòng (52%), Cần Thơ (48%)."
        )
    }

    # Bước 3: Đánh giá khả năng đáp ứng & lọc Leads
    $evaluatedTerritories = @()
    foreach ($ht in $harmonizedTerritories) {
        $orig = $GlobalData.territories | Where-Object { $_.id -eq $ht.id }
        $supportScore = 0
        $supportFeasibility = ""
        $qualifiedLeads = @()
        $disqualifiedLeads = @()

        if ($ht.id -eq "T1") { # Bình Dương
            $supportScore = 95
            $supportFeasibility = "RẤT CAO: Cách HQ 45km (1.2h). Đội 5 kỹ sư di chuyển linh hoạt trong ngày, đáp ứng 100% SLA."
            foreach ($l in $orig.leads) {
                if ($l.id -ne "L04") { $qualifiedLeads += $l } else { $disqualifiedLeads += $l }
            }
        } elseif ($ht.id -eq "T2") { # Đà Nẵng
            $supportScore = 82
            $supportFeasibility = "KHẢ THI: Có chuyến bay thẳng từ TP.HCM (1.5h). Phù hợp đào tạo tập trung và on-site 2 đợt/tháng."
            foreach ($l in $orig.leads) {
                if ($l.id -ne "L08") { $qualifiedLeads += $l } else { $disqualifiedLeads += $l }
            }
        } elseif ($ht.id -eq "T3") { # Cần Thơ
            $supportScore = 35
            $supportFeasibility = "RỦI RO CAO (QUÁ TẢI): Khách hàng yêu cầu trực kỹ thuật 24/7 on-site trong 3 tuần đầu. 1 team 5 người sẽ kiệt sức, phá vỡ SLA."
            foreach ($l in $orig.leads) {
                $disqualifiedLeads += $l
            }
        } elseif ($ht.id -eq "T4") { # Hải Phòng
            $supportScore = 45
            $supportFeasibility = "TRUNG BÌNH THẤP: Cách 1750km, chi phí di chuyển cao, quy mô triển khai đòi hỏi đội ngũ >= 10 người."
            foreach ($l in $orig.leads) {
                if ($l.id -eq "L12") { $qualifiedLeads += $l } else { $disqualifiedLeads += $l }
            }
        }

        # Normalized scores for criteria (0-100)
        $marketScore = [Math]::Min(100, [Math]::Round(($ht.clean_market_size / 230) * 100))
        $leadScore = [Math]::Round(($qualifiedLeads.Count / [Math]::Max(1, $orig.leads.Count)) * 100)
        
        $compScore = 50
        if ($ht.id -eq "T1") { $compScore = 75 } # Đối thủ phân tán, WMS bán lẻ Hưng Phát vượt trội tính năng barcode
        elseif ($ht.id -eq "T2") { $compScore = 85 } # Đối thủ công nghệ cũ desktop client, thị trường khao khát Cloud WMS
        elseif ($ht.id -eq "T3") { $compScore = 40 } # KiotViet/Sapo bao phủ giá rẻ
        elseif ($ht.id -eq "T4") { $compScore = 30 } # Đối thủ Phương Bắc phá giá 40% + Hệ sinh thái cảng biển độc quyền

        # Total Weighted Score
        $totalScore = [Math]::Round(
            ($ht.fit_score * $w_fit) +
            ($supportScore * $w_support) +
            ($marketScore * $w_market) +
            ($leadScore * $w_lead) +
            ($compScore * $w_comp), 1
        )

        $evaluatedTerritories += [PSCustomObject]@{
            id = $ht.id
            name = $ht.name
            region = $ht.region
            clean_market_size = $ht.clean_market_size
            sync_note = $ht.sync_note
            fit_score = $ht.fit_score
            support_score = $supportScore
            support_feasibility = $supportFeasibility
            market_score = $marketScore
            lead_score = $leadScore
            comp_score = $compScore
            total_score = [double]$totalScore
            qualified_leads_count = $qualifiedLeads.Count
            disqualified_leads_count = $disqualifiedLeads.Count
            qualified_leads = $qualifiedLeads
            disqualified_leads = $disqualifiedLeads
            competitors = $orig.competitors
        }
    }

    $steps += @{
        step = 3
        name = "Đánh Giá Khả Năng Đáp Ứng & Lọc Khách Hàng Tiềm Năng"
        status = "COMPLETED"
        summary = "Đã rà soát năng lực on-site đội 5 kỹ sư và phân loại qualified leads."
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        details = @(
            "Cần Thơ: Đánh giá RỦI RO ĐỎ do khách hàng đòi hỏi trực 24/7 on-site, vượt năng lực công ty.",
            "Bình Dương & Đà Nẵng: 100% phù hợp khả năng di chuyển và hỗ trợ SLA của Hưng Phát.",
            "Lọc thành công 7 leads chất lượng cao, loại bỏ các đơn vị đòi kho lạnh -30°C và cảng container."
        )
    }

    # Bước Quyết định & Bước 4: Sắp xếp và chọn Top 2
    $ranked = $evaluatedTerritories | Sort-Object -Property total_score -Descending
    $selectedTerritories = $ranked[0..1]
    $excludedTerritories = $ranked[2..3]

    $steps += @{
        step = 4
        name = "Áp Dụng Bộ Tiêu Chí & Quyết Định Lựa Chọn Top 2"
        status = "COMPLETED"
        summary = "Đã tính điểm tổng hợp đa tiêu chí. Xác định 2 địa bàn chiến lược tối ưu nhất để khảo sát."
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        details = @(
            "Hạng 1: $($ranked[0].name) - Điểm tổng hợp: $($ranked[0].total_score)/100",
            "Hạng 2: $($ranked[1].name) - Điểm tổng hợp: $($ranked[1].total_score)/100",
            "Loại trừ: $($ranked[2].name) ($($ranked[2].total_score) điểm) và $($ranked[3].name) ($($ranked[3].total_score) điểm)"
        )
    }

    $steps += @{
        step = 5
        name = "Lập Hồ Sơ Nghiên Cứu & Đề Xuất Khảo Sát (Audit Ready)"
        status = "COMPLETED"
        summary = "Hồ sơ đề xuất đã hoàn tất, có đầy đủ căn cứ kiểm chứng, mã đối soát và sẵn sàng trình Ban Giám Đốc."
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        details = @(
            "Mã hồ sơ: HP-EXP-2026-Q1",
            "Địa bàn lựa chọn chính thức: $($selectedTerritories[0].name) & $($selectedTerritories[1].name)",
            "Kế hoạch tiếp theo: Tiến hành khảo sát thực địa 7 khách hàng mục tiêu đã qualified."
        )
    }

    return @{
        run_id = [Guid]::NewGuid().ToString()
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        weights_used = @{
            fit_score = $w_fit
            support_feasibility = $w_support
            market_size = $w_market
            lead_quality = $w_lead
            competition_pressure = $w_comp
        }
        steps = $steps
        ranked_territories = $ranked
        selected = $selectedTerritories
        excluded = $excludedTerritories
        recommendation_justification = @{
            why_top2 = "Địa bàn A (Bình Dương) và Địa bàn B (Đà Nẵng) đạt điểm vượt trội về độ khớp giải pháp WMS (>88%) và khả năng hỗ trợ tại chỗ hoàn toàn nằm trong tầm kiểm soát của đội triển khai 5 người. Đảm bảo tỷ lệ chuyển đổi cao và tối ưu chi phí vận hành."
            why_excluded_can_tho = "Địa bàn C (Cần Thơ) quy mô báo cáo bị thổi phồng bởi hộ kinh doanh cá thể; nhu cầu kho lạnh sâu lệch khỏi danh mục WMS; và yêu cầu kỹ sư trực 24/7 on-site vượt quá khả năng đội ngũ Hưng Phát."
            why_excluded_hai_phong = "Địa bàn D (Hải Phòng) thị trường chủ yếu là kho logistics cảng biển (lệch WMS bán lẻ), đối thủ địa phương đang phá giá 40%, chi phí hỗ trợ xa xôi không hiệu quả cho đợt mở rộng duy nhất này."
        }
    }
}

function Generate-ChatResponse($userMessage, $pipelineResult) {
    $msg = $userMessage.ToLower()
    $reply = ""

    if ($msg -like "*cần thơ*" -or $msg -like "*can tho*" -or $msg -like "*tại sao loại*") {
        $reply = "### Phân tích AI Agent: Lý do loại trừ Địa bàn C (Cần Thơ & ĐBSCL)

AI Agent đã thực hiện kiểm tra chéo và phát hiện 3 điểm 'báo động đỏ' sau:

1. **Số liệu thị trường bị 'thổi phồng' và lệch kỳ**: Báo cáo ban đầu ghi 310 đơn vị (số liệu cũ 2023). Sau khi đối soát, phát hiện có tới 180 hộ kinh doanh đơn lẻ / vựa gạo không có nhu cầu WMS chuỗi. Quy mô chuỗi thực tế chỉ còn ~75 đơn vị.
2. **Lệch giải pháp cốt lõi**: Khách hàng tại Cần Thơ chủ yếu yêu cầu quản lý kho lạnh âm sâu chuyên biệt (< -25°C) cho thủy hải sản và nông sản xuất khẩu — đây là giới hạn kỹ thuật của WMS Hưng Phát hiện tại.
3. **Vượt ngưỡng hỗ trợ tại chỗ (On-site Overload)**: Khách hàng lớn (như Chuỗi Nông sản Mekong) đòi hỏi kỹ sư trực on-site 24/7 trong 3 tuần đầu. Với duy nhất 1 đội triển khai 5 người, việc này sẽ làm tê liệt toàn bộ hoạt động hỗ trợ khách hàng hiện tại của Hưng Phát.

Do đó, việc loại trừ Cần Thơ là quyết định bắt buộc để bảo toàn chất lượng dịch vụ và nguồn lực."
    } elseif ($msg -like "*đà nẵng*" -or $msg -like "*da nang*" -or $msg -like "*rủi ro*") {
        $reply = "### Phân tích AI Agent: Đánh giá cơ hội & Rủi ro tại Địa bàn B (Đà Nẵng)

**1. Cơ hội chiến lược:**
- Thị trường tăng trưởng mạnh 22%/năm về chuỗi bán lẻ du lịch, quà tặng, thời trang.
- Đối thủ tại chỗ chủ yếu là phần mềm Desktop cũ kỹ, thị trường rất 'khát' giải pháp Cloud WMS hiện đại.
- Độ khớp tính năng đạt **88%** (Barcode 2D, điều chuyển đa chi nhánh, cross-docking).

**2. Điểm cần lưu ý đã được Agent làm sạch:**
- Nhân viên ban đầu cộng gộp 2 báo cáo thành 320 chuỗi. Agent phát hiện Tạp chí Logistics sao chép 100% từ VCCI Đà Nẵng, đã chuẩn hóa về đúng **160 chuỗi thực tế**.

**3. Phương án ứng phó năng lực triển khai:**
- Đà Nẵng cách 850km nhưng có đường bay thẳng (1.5h). Đội 5 người áp dụng mô hình: Đào tạo online 70% + Cử 2 kỹ sư on-site 3 ngày trong tuần Go-live. Đảm bảo đúng SLA mà không gây quá tải."
    } elseif ($msg -like "*hải phòng*" -or $msg -like "*hai phong*" -or $msg -like "*ban giám đốc ép*") {
        $reply = "### Kịch bản phản biện Ban Giám Đốc nếu bị yêu cầu chọn Hải Phòng:

Trưởng phòng Kinh doanh có thể trình bày các luận cứ kiểm định sau:

1. **Thị trường không khớp phân khúc mục tiêu**: Báo cáo ghi 185 doanh nghiệp nhưng có tới 70% là kho logistics cảng biển container và kho ngoại quan hải quan. Phân khúc chuỗi bán lẻ thuần túy chỉ có ~55 đơn vị.
2. **Cuộc chiến giá khốc liệt**: Đối thủ Phương Bắc WMS đang phá giá 40%, cùng các công ty cảng độc quyền trợ giá hệ sinh thái. Hưng Phát bước vào sẽ bị cuốn vào cạnh tranh giá, biên lợi nhuận thấp.
3. **Chi phí và cự ly hỗ trợ**: Cách HQ 1.750km, nếu xảy ra sự cố cần hỗ trợ tại chỗ, chi phí vé máy bay và thời gian di chuyển sẽ ăn mòn toàn bộ doanh thu hợp đồng.
4. **Kiến nghị với BGĐ**: Chỉ nên mở rộng Hải Phòng ở đợt sau khi Hưng Phát thành lập chi nhánh miền Bắc và bổ sung module WMS Cảng biển."
    } elseif ($msg -like "*tuyển thêm*" -or $msg -like "*nhân sự*" -or $msg -like "*thêm kỹ sư*") {
        $reply = "### Mô phỏng tình huống (What-If Analysis): Tuyển thêm 3 kỹ sư triển khai

Nếu Ban Giám đốc phê duyệt tuyển thêm 3 kỹ sư (nâng đội ngũ lên 8 người):
- **Khả năng phục vụ**: Có thể mở rộng đồng thời 3 địa bàn thay vì 2.
- **Tác động đến Cần Thơ**: Vẫn **KHÔNG NÊN** chọn, vì rào cản chính ở Cần Thơ là **độ lệch tính năng kho lạnh âm sâu**, không chỉ đơn thuần là thiếu người.
- **Tác động đến Hải Phòng**: Có thể cân nhắc đưa vào diện dự phòng nếu tuyển được kỹ sư am hiểu thị trường miền Bắc.
- **Khuyến nghị tối ưu**: Dù có thêm 3 nhân sự, Top 2 vẫn phải là **Bình Dương & Đà Nẵng** để đảm bảo tỷ lệ thành công 100% trước khi dàn trải lực lượng."
    } else {
        $reply = "Xin chào Trưởng phòng! Tôi là AI Agent Hỗ trợ Quyết định Mở rộng Thị trường của Công ty Hưng Phát.

Dựa trên gói dữ liệu đã chuẩn hóa và 10 bước của quy trình kiểm toán:
- **Đề xuất tối ưu**: Lựa chọn **Địa bàn A (Bình Dương)** và **Địa bàn B (Đà Nẵng)** để tiến hành khảo sát khách hàng.
- **Đã sàng lọc**: Khử 178 bản ghi trùng lặp/ảo, loại bỏ 2 địa bàn có rủi ro vượt quá năng lực hỗ trợ tại chỗ (Cần Thơ) và cạnh tranh phá giá (Hải Phòng).

Bạn có thể hỏi tôi về:
1. *'Tại sao loại Cần Thơ dù khách hàng rất quan tâm?'*
2. *'Đà Nẵng có rủi ro gì và phương án giải quyết?'*
3. *'Cách phản biện nếu Ban Giám đốc muốn mở Hải Phòng?'*
4. *'Tác động nếu tuyển thêm kỹ sư triển khai?'*"
    }

    return @{
        reply = $reply
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
}

Write-Host "Server dang san sang tiep nhan yeu cau..." -ForegroundColor Green

while ($Listener.IsListening) {
    try {
        $Context = $Listener.GetContext()
        $Request = $Context.Request
        $Response = $Context.Response

        $UrlPath = $Request.Url.AbsolutePath
        $HttpMethod = $Request.HttpMethod

        # CORS Headers
        $Response.AddHeader("Access-Control-Allow-Origin", "*")
        $Response.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $Response.AddHeader("Access-Control-Allow-Headers", "Content-Type")

        if ($HttpMethod -eq "OPTIONS") {
            $Response.StatusCode = 200
            $Response.Close()
            continue
        }

        # Route: API
        if ($UrlPath -eq "/api/data" -and $HttpMethod -eq "GET") {
            $json = ConvertTo-Json $GlobalData -Depth 10
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $Response.ContentType = "application/json; charset=utf-8"
            $Response.ContentLength64 = $buffer.Length
            $Response.OutputStream.Write($buffer, 0, $buffer.Length)
            $Response.Close()
            continue
        }

        if ($UrlPath -eq "/api/run-pipeline" -and $HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($Request.InputStream, $Request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $reader.Close()

            $customWeights = $null
            if ($body) {
                try {
                    $customWeights = $body | ConvertFrom-Json
                } catch {}
            }

            $res = Run-AgentPipeline $customWeights
            $json = ConvertTo-Json $res -Depth 10
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $Response.ContentType = "application/json; charset=utf-8"
            $Response.ContentLength64 = $buffer.Length
            $Response.OutputStream.Write($buffer, 0, $buffer.Length)
            $Response.Close()
            continue
        }

        if ($UrlPath -eq "/api/chat" -and $HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($Request.InputStream, $Request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $reader.Close()

            $userMessage = ""
            if ($body) {
                try {
                    $parsed = $body | ConvertFrom-Json
                    $userMessage = $parsed.message
                } catch {}
            }

            $chatRes = Generate-ChatResponse $userMessage $null
            $json = ConvertTo-Json $chatRes -Depth 10
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $Response.ContentType = "application/json; charset=utf-8"
            $Response.ContentLength64 = $buffer.Length
            $Response.OutputStream.Write($buffer, 0, $buffer.Length)
            $Response.Close()
            continue
        }

        # Static File Serving
        $filePath = ""
        if ($UrlPath -eq "/" -or $UrlPath -eq "") {
            $filePath = Join-Path $ScriptDir "index.html"
        } else {
            $rel = $UrlPath.TrimStart("/").Replace("/", "\")
            $filePath = Join-Path $ScriptDir $rel
        }

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath)
            $Response.ContentType = Get-MimeType $ext
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $Response.ContentLength64 = $bytes.Length
            if ($HttpMethod -ne "HEAD") {
                $Response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            $Response.Close()
        } else {
            # 404
            $Response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $UrlPath")
            $Response.ContentLength64 = $errBytes.Length
            $Response.OutputStream.Write($errBytes, 0, $errBytes.Length)
            $Response.Close()
        }
    } catch {
        Write-Warning "Loi xu ly request: $_"
    }
}
