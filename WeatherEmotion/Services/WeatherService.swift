//
//  WeatherService.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import Foundation
import CoreLocation

// MARK: - WeatherService
/// 날씨 정보를 가져오는 서비스 클래스 (위치 관리 포함)
class WeatherService: NSObject, ObservableObject {
    // MARK: - Properties
    private let apiKey = "dfe681564a7b190f03781f2a3cb641cc"
    private let locationManager = CLLocationManager()
    
    @Published var weather: Weather?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: - Initialization
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // MARK: - Public Methods
    
    /// 위치 권한 요청
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// 현재 위치 기반 날씨 가져오기
    func fetchCurrentWeather() {
        isLoading = true
        errorMessage = nil
        
        // 권한 상태 확인
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ 위치 권한 허용됨")
            locationManager.requestLocation()
        case .denied, .restricted:
            print("❌ 위치 권한 거부됨")
            isLoading = false
            errorMessage = "위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요."
        case .notDetermined:
            print("⚠️ 위치 권한 미결정. 테스트 모드로 서울 날씨 사용")
            // 권한 요청은 하지만, 즉시 테스트 위치 사용
            requestLocationPermission()
            Task {
                await fetchWeather(latitude: 37.5665, longitude: 126.9780) // 서울
            }
        @unknown default:
            isLoading = false
            errorMessage = "알 수 없는 위치 권한 상태입니다."
        }
    }
    
    // MARK: - Private Methods
    
    /// OpenWeatherMap API 호출
    private func fetchWeather(latitude: Double, longitude: Double) async {
        // URL 구성 (units=metric: 섭씨 온도, lang=kr: 한국어 응답)
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric&lang=kr"
        
        print("🌐 날씨 API 호출 시작: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ URL 생성 실패")
            await MainActor.run {
                self.errorMessage = "잘못된 URL입니다."
                self.isLoading = false
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // HTTP 상태 코드 확인
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ HTTP 응답 변환 실패")
                await MainActor.run {
                    self.errorMessage = "서버 응답 오류입니다."
                    self.isLoading = false
                }
                return
            }
            
            print("📡 HTTP 상태 코드: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let responseString = String(data: data, encoding: .utf8) ?? "응답 없음"
                print("❌ API 에러 응답: \(responseString)")
                await MainActor.run {
                    self.errorMessage = "서버 응답 오류입니다. (코드: \(httpResponse.statusCode))"
                    self.isLoading = false
                }
                return
            }
            
            // JSON 디코딩
            let decodedResponse = try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
            let weatherModel = decodedResponse.toWeather()
            
            print("✅ 날씨 정보 수신 성공: \(weatherModel.localizedCondition) \(weatherModel.displayTemperature)")
            
            await MainActor.run {
                self.weather = weatherModel
                self.isLoading = false
            }
            
        } catch {
            print("❌ 날씨 데이터 로드 실패: \(error)")
            await MainActor.run {
                self.errorMessage = "날씨 데이터 로드 실패: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension WeatherService: CLLocationManagerDelegate {
    /// 위치 권한 상태 변경 시 호출
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 위치 권한 상태 변경: \(manager.authorizationStatus.rawValue)")
        self.authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ 위치 권한 허용됨. 위치 요청 시작...")
            isLoading = true
            manager.requestLocation()
        case .denied:
            print("❌ 위치 권한 거부됨")
            errorMessage = "위치 권한이 거부되었습니다."
            isLoading = false
        case .notDetermined:
            print("⏳ 위치 권한 미결정 상태")
        default:
            break
        }
    }
    
    /// 위치 정보 업데이트 성공 시 호출
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("❌ 위치 정보 없음")
            return
        }
        
        print("✅ 위치 정보 수신: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // 위치를 받으면 비동기로 날씨 API 호출
        Task {
            await fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }
    
    /// 위치 정보 업데이트 실패 시 호출
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ 위치 정보 오류: \(error.localizedDescription)")
        isLoading = false
        errorMessage = "위치 정보를 가져올 수 없습니다: \(error.localizedDescription)"
    }
}
