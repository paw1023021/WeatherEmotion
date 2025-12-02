//
//  WeatherViewModel.swift
//  WeatherEmotion
//
//  Created by dsu_student on 11/25/25.
//

import Foundation
import Combine
import CoreLocation

// MARK: - WeatherViewModel
/// 날씨 화면의 상태를 관리하는 ViewModel
@MainActor
class WeatherViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var weather: Weather?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showPermissionAlert: Bool = false
    
    // MARK: - Private Properties
    private let weatherService = WeatherService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        bindService()
    }
    
    // MARK: - Public Methods
    
    /// 날씨 정보 로드 요청 (GPS 기반)
    func loadWeather() {
        weatherService.fetchCurrentWeather()
    }
    
    /// 위치 권한 요청
    func requestPermission() {
        weatherService.requestLocationPermission()
    }
    
    // MARK: - Private Methods
    
    /// WeatherService의 상태를 구독하여 ViewModel 상태 업데이트
    private func bindService() {
        // 날씨 데이터 바인딩
        weatherService.$weather
            .receive(on: DispatchQueue.main)
            .assign(to: \.weather, on: self)
            .store(in: &cancellables)
            
        // 로딩 상태 바인딩
        weatherService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
            
        // 에러 메시지 바인딩
        weatherService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
            
        // 권한 상태 바인딩 및 처리
        weatherService.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                
                switch status {
                case .denied, .restricted:
                    self.showPermissionAlert = true
                    self.errorMessage = "위치 권한이 거부되었습니다. 설정에서 허용해주세요."
                case .authorizedWhenInUse, .authorizedAlways:
                    self.showPermissionAlert = false
                    // 권한이 허용되면 자동으로 날씨 요청
                    if self.weather == nil {
                        self.loadWeather()
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
