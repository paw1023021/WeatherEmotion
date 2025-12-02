import Foundation

// MARK: - Weather Model
/// 날씨 정보를 담는 데이터 모델
struct Weather: Codable, Identifiable {
    let id: UUID                // 고유 식별자
    let temperature: Double     // 현재 온도 (섭씨)
    let condition: String       // 날씨 상태 (영문: Clear, Rain, Clouds, Snow 등)
    let humidity: Int           // 습도 (%)
    let location: String        // 위치 정보
    let timestamp: Date         // 날씨 조회 시간
    
    // 기본 생성자
    init(id: UUID = UUID(), temperature: Double, condition: String, humidity: Int, location: String, timestamp: Date = Date()) {
        self.id = id
        self.temperature = temperature
        self.condition = condition
        self.humidity = humidity
        self.location = location
        self.timestamp = timestamp
    }
    
    // MARK: - Computed Properties
    
    /// UI 표시용 온도 문자열 (예: "24°C")
    var displayTemperature: String {
        return "\(Int(temperature))°C"
    }
    
    /// 날씨 상태에 따른 SF Symbols 아이콘 이름
    var weatherIcon: String {
        switch condition.lowercased() {
        case "clear", "sunny":
            return "sun.max.fill"
        case "rain", "rainy", "drizzle":
            return "cloud.rain.fill"
        case "clouds", "cloudy":
            return "cloud.fill"
        case "snow", "snowy":
            return "snow"
        case "thunderstorm":
            return "cloud.bolt.fill"
        case "mist", "fog", "haze":
            return "cloud.fog.fill"
        default:
            return "cloud.sun.fill"
        }
    }
    
    /// 날씨에 따른 배경 그라데이션 색상 (Hex 코드 배열)
    var gradientColors: [String] {
        switch condition.lowercased() {
        case "clear", "sunny":
            return ["FFE68A", "FFD93D"]     // 밝은 노란색 계열 (맑음)
        case "rain", "rainy", "drizzle":
            return ["A7C7E7", "6FA8DC"]     // 블루 계열 (비)
        case "clouds", "cloudy":
            return ["B8B8D0", "8E8EA8"]     // 회색 계열 (흐림)
        case "snow", "snowy":
            return ["E3F2FD", "BBDEFB"]     // 라이트 블루 (눈)
        case "thunderstorm":
            return ["5E6472", "3D4451"]     // 어두운 회색 (천둥번개)
        default:
            return ["B4E7FF", "87CEEB"]     // 기본 하늘색
        }
    }
    
    /// 한글 날씨 설명
    var localizedCondition: String {
        switch condition.lowercased() {
        case "clear", "sunny":
            return "맑음"
        case "rain", "rainy":
            return "비"
        case "drizzle":
            return "이슬비"
        case "clouds", "cloudy":
            return "흐림"
        case "snow", "snowy":
            return "눈"
        case "thunderstorm":
            return "천둥번개"
        case "mist", "fog":
            return "안개"
        case "haze":
            return "실안개"
        default:
            return "알 수 없음"
        }
    }
    
    /// 날씨 상세 정보 문자열 (예: "맑음, 24°C, 습도 60%")
    var detailedDescription: String {
        return "\(localizedCondition), \(displayTemperature), 습도 \(humidity)%"
    }
}

// MARK: - OpenWeatherMap API Response Models
/// OpenWeatherMap API 응답을 파싱하기 위한 구조체
struct WeatherAPIResponse: Codable {
    let main: MainWeather
    let weather: [WeatherCondition]
    let name: String
    
    /// 온도 및 습도 정보
    struct MainWeather: Codable {
        let temp: Double
        let humidity: Int
    }
    
    /// 날씨 상태 정보
    struct WeatherCondition: Codable {
        let main: String        // 간략한 날씨 상태 (Clear, Rain 등)
        let description: String // 상세 설명
    }
    
    /// API 응답을 Weather 모델로 변환
    func toWeather() -> Weather {
        return Weather(
            temperature: main.temp,
            condition: weather.first?.main ?? "Unknown",
            humidity: main.humidity,
            location: name
        )
    }
}
