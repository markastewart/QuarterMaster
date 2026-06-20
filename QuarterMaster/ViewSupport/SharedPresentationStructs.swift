//
//  SharedPresentationStructs.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/20/26.
//

import Foundation


struct TaxEstimateResultMap {
    let keyPath: KeyPath<TaxEstimate, Double>
    let displayName: String
}


struct DrilldownRowConfig {
    let displayName: String
    let extract: (QuarterlyInput?, TaxEstimate?) -> Double
}
