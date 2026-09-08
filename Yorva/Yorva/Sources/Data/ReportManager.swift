//
//  ReportManager.swift
//  Yorva
//
//

import Foundation

final class ReportManager {

    static let shared = ReportManager()

    private let key = "yorva.report.records.v1"
    private(set) var records: [ReportRecord] = []

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([ReportDTO].self, from: data) {
            records = decoded.map { $0.toRecord() }
        }
    }

    @discardableResult
    func report(reporterId: String, targetUserId: String, reason: ReportReason, detail: String = "") -> ReportRecord {
        let record = ReportRecord(
            id: "report-\(records.count + 1)",
            reporterId: reporterId,
            targetUserId: targetUserId,
            reason: reason,
            detail: detail,
            createdAt: Date()
        )
        records.append(record)
        persist()
        DataRepository.shared.broadcast(.reportSubmitted)
        return record
    }

    func hasReported(_ targetUserId: String, by reporterId: String) -> Bool {
        records.contains { $0.reporterId == reporterId && $0.targetUserId == targetUserId }
    }

    private func persist() {
        let dtos = records.map { ReportDTO(from: $0) }
        if let data = try? JSONEncoder().encode(dtos) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

private struct ReportDTO: Codable {
    let id: String
    let reporterId: String
    let targetUserId: String
    let reason: String
    let detail: String
    let createdAt: TimeInterval
    init(from r: ReportRecord) {
        id = r.id; reporterId = r.reporterId; targetUserId = r.targetUserId
        reason = r.reason.rawValue; detail = r.detail; createdAt = r.createdAt.timeIntervalSince1970
    }
    func toRecord() -> ReportRecord {
        ReportRecord(id: id, reporterId: reporterId, targetUserId: targetUserId,
                     reason: ReportReason(rawValue: reason) ?? .other,
                     detail: detail, createdAt: Date(timeIntervalSince1970: createdAt))
    }
}
