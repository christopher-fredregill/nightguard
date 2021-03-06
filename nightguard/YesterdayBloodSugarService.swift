//
//  YesterdayComparisonValues.swift
//  scoutwatch
//
//  Created by Dirk Hermanns on 25.04.16.
//  Copyright © 2016 private. All rights reserved.
//

import Foundation

// Contains the blood values from the day before
class YesterdayBloodSugarService {
    
    static let singleton = YesterdayBloodSugarService()
    
    let ONE_DAY_IN_MICROSECONDS = Double(60*60*24*1000)
    
    var bloodSugarArray : [BloodSugar] = []
    
    func warmupCache() {
        if needsToBeRefreshed() {
            NightscoutService.singleton.readYesterdaysChartData({bloodValues -> Void in
                
                self.bloodSugarArray = bloodValues
            })
        }
    }
    
    func getYesterdaysValues(_ resultHandler : @escaping (([BloodSugar]) -> Void)) {
        if needsToBeRefreshed() {
            NightscoutService.singleton.readYesterdaysChartData({bloodValues -> Void in
                
                self.bloodSugarArray = bloodValues
                resultHandler(self.bloodSugarArray)
            })
        } else {
            resultHandler(bloodSugarArray)
        }
    }

    /* Gets yesterdays blood values and transform these to the current day.
       Therefore they can be compared in one diagram. */
    func getYesterdaysValuesTransformedToCurrentDay(_ resultHandler : @escaping (([BloodSugar]) -> Void)) {
        
        getYesterdaysValues() { yesterdaysValues in
            
            var transformedValues : [BloodSugar] = []
            for yesterdaysValue in yesterdaysValues {
                let transformedValue = BloodSugar.init(value: yesterdaysValue.value, timestamp: yesterdaysValue.timestamp + self.ONE_DAY_IN_MICROSECONDS)
                transformedValues.append(transformedValue)
            }
            
            resultHandler(transformedValues)
        }
    }
    
    func filteredValues(_ from : Double, to : Double) -> [BloodSugar] {
        var filteredValues : [BloodSugar] = []
        
        for bloodSugar in bloodSugarArray {
            if isInRangeRegardingHoursAndMinutes(bloodSugar, from: from, to: to) {
                filteredValues.append(bloodSugar)
            }
        }
        
        return filteredValues
    }
    
    fileprivate func isInRangeRegardingHoursAndMinutes(_ bloodSugar : BloodSugar, from : Double, to : Double) -> Bool {
        
        // set from / to time one day back in time
        // so the time is the only that is compared
        
        let yesterdayFrom = from - ONE_DAY_IN_MICROSECONDS
        let yesterdayTo = to - ONE_DAY_IN_MICROSECONDS
        
        return yesterdayFrom <= bloodSugar.timestamp && bloodSugar.timestamp <= yesterdayTo
    }
    
    fileprivate func needsToBeRefreshed() -> Bool {
        if bloodSugarArray.count == 0 {
            return true
        }
        
        return !TimeService.isYesterday(bloodSugarArray[0].timestamp)
    }
}
