//
//  DataBrokerOperation.swift
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import Common

protocol DataBrokerOperationDependencies {
    var database: DataBrokerProtectionRepository { get }
    var config: DataBrokerExecutionConfig { get }
    var runnerProvider: JobRunnerProvider { get }
    var notificationCenter: NotificationCenter { get }
    var pixelHandler: EventMapping<DataBrokerProtectionPixels> { get }
    var userNotificationService: DataBrokerProtectionUserNotificationService { get }
}

struct DefaultDataBrokerOperationDependencies: DataBrokerOperationDependencies {
    let database: DataBrokerProtectionRepository
    var config: DataBrokerExecutionConfig
    let runnerProvider: JobRunnerProvider
    let notificationCenter: NotificationCenter
    let pixelHandler: EventMapping<DataBrokerProtectionPixels>
    let userNotificationService: DataBrokerProtectionUserNotificationService
}

enum OperationType {
    case scan
    case optOut
    case all
}

protocol DataBrokerOperationErrorDelegate: AnyObject {
    func dataBrokerOperationDidError(_ error: Error, withBrokerName brokerName: String?)
}

// swiftlint:disable explicit_non_final_class
class DataBrokerOperation: Operation, @unchecked Sendable {

    private let dataBrokerID: Int64
    private let operationType: OperationType
    private let priorityDate: Date? // The date to filter and sort operations priorities
    private let showWebView: Bool
    private(set) weak var errorDelegate: DataBrokerOperationErrorDelegate? // Internal read-only to enable mocking
    private let operationDependencies: DataBrokerOperationDependencies

    private let id = UUID()
    private var _isExecuting = false
    private var _isFinished = false

    deinit {
        os_log("Deinit operation: %{public}@", log: .dataBrokerProtection, String(describing: id.uuidString))
    }

    init(dataBrokerID: Int64,
         operationType: OperationType,
         priorityDate: Date? = nil,
         showWebView: Bool,
         errorDelegate: DataBrokerOperationErrorDelegate,
         operationDependencies: DataBrokerOperationDependencies) {

        self.dataBrokerID = dataBrokerID
        self.priorityDate = priorityDate
        self.operationType = operationType
        self.showWebView = showWebView
        self.errorDelegate = errorDelegate
        self.operationDependencies = operationDependencies
        super.init()
    }

    override func start() {
        if isCancelled {
            finish()
            return
        }

        willChangeValue(forKey: #keyPath(isExecuting))
        _isExecuting = true
        didChangeValue(forKey: #keyPath(isExecuting))

        main()
    }

    override var isAsynchronous: Bool {
        return true
    }

    override var isExecuting: Bool {
        return _isExecuting
    }

    override var isFinished: Bool {
        return _isFinished
    }

    override func main() {
        Task {
            await runOperation()
            finish()
        }
    }

    private func filterAndSortOperationsData(brokerProfileQueriesData: [BrokerProfileQueryData], operationType: OperationType, priorityDate: Date?) -> [BrokerJobData] {
        let operationsData: [BrokerJobData]

        switch operationType {
        case .optOut:
            operationsData = brokerProfileQueriesData.flatMap { $0.optOutJobData }
        case .scan:
            operationsData = brokerProfileQueriesData.filter { $0.profileQuery.deprecated == false }.compactMap { $0.scanJobData }
        case .all:
            operationsData = brokerProfileQueriesData.flatMap { $0.operationsData }
        }

        let filteredAndSortedOperationsData: [BrokerJobData]

        if let priorityDate = priorityDate {
            filteredAndSortedOperationsData = operationsData
                .filter { $0.preferredRunDate != nil && $0.preferredRunDate! <= priorityDate }
                .sorted { $0.preferredRunDate! < $1.preferredRunDate! }
        } else {
            filteredAndSortedOperationsData = operationsData
        }

        return filteredAndSortedOperationsData
    }

    private func runOperation() async {
        let allBrokerProfileQueryData: [BrokerProfileQueryData]

        do {
            allBrokerProfileQueryData = try operationDependencies.database.fetchAllBrokerProfileQueryData()
        } catch {
            os_log("DataBrokerOperationsCollection error: runOperation, error: %{public}@", log: .error, error.localizedDescription)
            return
        }

        let brokerProfileQueriesData = allBrokerProfileQueryData.filter { $0.dataBroker.id == dataBrokerID }

        let filteredAndSortedOperationsData = filterAndSortOperationsData(brokerProfileQueriesData: brokerProfileQueriesData,
                                                                          operationType: operationType,
                                                                          priorityDate: priorityDate)

        os_log("filteredAndSortedOperationsData count: %{public}d for brokerID %{public}d", log: .dataBrokerProtection, filteredAndSortedOperationsData.count, dataBrokerID)

        for operationData in filteredAndSortedOperationsData {
            if isCancelled {
                os_log("Cancelled operation, returning...", log: .dataBrokerProtection)
                return
            }

            let brokerProfileData = brokerProfileQueriesData.filter {
                $0.dataBroker.id == operationData.brokerId && $0.profileQuery.id == operationData.profileQueryId
            }.first

            guard let brokerProfileData = brokerProfileData else {
                continue
            }
            do {
                os_log("Running operation: %{public}@", log: .dataBrokerProtection, String(describing: operationData))

                try await DataBrokerProfileQueryOperationManager().runOperation(operationData: operationData,
                                                                                brokerProfileQueryData: brokerProfileData,
                                                                                database: operationDependencies.database,
                                                                                notificationCenter: operationDependencies.notificationCenter,
                                                                                runner: operationDependencies.runnerProvider.getJobRunner(),
                                                                                pixelHandler: operationDependencies.pixelHandler,
                                                                                showWebView: showWebView,
                                                                                isImmediateOperation: operationType == .scan,
                                                                                userNotificationService: operationDependencies.userNotificationService,
                                                                                shouldRunNextStep: { [weak self] in
                    guard let self = self else { return false }
                    return !self.isCancelled
                })

                let sleepInterval = operationDependencies.config.intervalBetweenSameBrokerOperations
                os_log("Waiting...: %{public}f", log: .dataBrokerProtection, sleepInterval)
                try await Task.sleep(nanoseconds: UInt64(sleepInterval) * 1_000_000_000)
            } catch {
                os_log("Error: %{public}@", log: .dataBrokerProtection, error.localizedDescription)

                errorDelegate?.dataBrokerOperationDidError(error, withBrokerName: brokerProfileQueriesData.first?.dataBroker.name)
            }
        }

        finish()
    }

    private func finish() {
        willChangeValue(forKey: #keyPath(isExecuting))
        willChangeValue(forKey: #keyPath(isFinished))

        _isExecuting = false
        _isFinished = true

        didChangeValue(forKey: #keyPath(isExecuting))
        didChangeValue(forKey: #keyPath(isFinished))

        os_log("Finished operation: %{public}@", log: .dataBrokerProtection, String(describing: id.uuidString))
    }
}
// swiftlint:enable explicit_non_final_class
