//
//  extensionsViewControllertabMain.swift
//  rcloneosx
//
//  Created by Thomas Evensen on 03.06.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable cyclomatic_complexity function_body_length file_length line_length

import Foundation
import Cocoa

extension ViewControllertabMain: NSTableViewDataSource {
    // Delegate for size of table
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.configurations?.configurationsDataSourcecount() ?? 0
    }
}

extension ViewControllertabMain: NSTableViewDelegate, Attributedestring {

    // TableView delegates
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if row > self.configurations!.configurationsDataSourcecount() - 1 { return nil }
        let object: NSDictionary = self.configurations!.getConfigurationsDataSource()![row]
        let markdays: Bool = self.configurations!.getConfigurations()[row].markdays
        let celltext = object[tableColumn!.identifier] as? String
        if tableColumn!.identifier.rawValue == "daysID" {
            if markdays {
                return self.attributedstring(str: celltext!, color: NSColor.red, align: .right)
            } else {
                return object[tableColumn!.identifier] as? String
            }
        } else if tableColumn!.identifier.rawValue == "statCellID" {
                if row == self.index {
                    if self.singletask == nil {
                        return #imageLiteral(resourceName: "yellow")
                    } else {
                        return #imageLiteral(resourceName: "green")
                    }
                }
        } else {
            if tableColumn!.identifier.rawValue == "batchCellID" {
                return object[tableColumn!.identifier] as? Int
            } else {
                return object[tableColumn!.identifier] as? String
            }
        }
        return nil
    }

    // Toggling batch
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if self.process != nil {
            self.abortOperations()
        }
        self.configurations!.enabledisablebatch(row)
        self.singletask = nil
        self.batchtasks = nil
    }
}

// Get output from rclone command
extension ViewControllertabMain: GetOutput {
    // Get information from rclone output.
    func getoutput() -> [String] {
        if self.outputbatch != nil {
            return self.outputbatch!.getOutput()
        } else if self.outputprocess != nil {
            return self.outputprocess!.trimoutput(trim: .two)!
        } else {
            return [""]
        }
    }
}

// Scheduled task are changed, read schedule again og redraw table
extension ViewControllertabMain: Reloadandrefresh {
    // Refresh tableView in main
    func reloadtabledata() {
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }
}

// Parameters to rclone is changed
extension ViewControllertabMain: RcloneUserParams {
    // Do a reread of all Configurations
    func rcloneuserparamsupdated() {
        self.showrclonecommandmainview()
    }
}

// Get index of selected row
extension ViewControllertabMain: GetSelecetedIndex {
    func getindex() -> Int? {
        return self.index
    }
}

// rclone path is changed, update displayed rclone command
extension ViewControllertabMain: RcloneIsChanged {
    // If row is selected an update rclone command in view
    func rcloneischanged() {
        // Update rclone command in display
        self.showrclonecommandmainview()
        self.setinfoaboutrclone()
    }
}

// Uuups, new version is discovered
extension ViewControllertabMain: NewVersionDiscovered {
    // Notifies if new version is discovered
    func notifyNewVersion() {
        guard Activetab(viewcontroller: .vctabmain).isactive == true else { return }
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.newVersionViewController!)
        })
    }
}

// Dismisser for sheets
extension ViewControllertabMain: DismissViewController {
    // Function for dismissing a presented view
    func dismiss_view(viewcontroller: NSViewController) {
        self.dismiss(viewcontroller)
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
            self.displayProfile()
        })
        self.setinfoaboutrclone()
    }
}

extension ViewControllertabMain: DismissViewEstimating {
    func dismissestimating(viewcontroller: NSViewController) {
        self.dismiss(viewcontroller)
    }
}

// Called when either a terminatopn of Process is
// discovered or data is availiable in the filehandler
// See file rcloneProcess.swift.
extension ViewControllertabMain: UpdateProgress {
    // Delegate functions called from the Process object
    // Protocol UpdateProgress two functions, ProcessTermination() and FileHandler()
    func processTermination() {
        self.readyforexecution = true
        if self.configurations!.processtermination == nil {
            self.configurations!.processtermination = .singlequicktask
        }
        switch self.configurations!.processtermination! {
        case .singletask:
            guard self.singletask != nil else { return }
            self.outputprocess = self.singletask!.outputprocess
            self.process = self.singletask!.process
            self.singletask!.processTermination()
        case .batchtask:
            self.batchtasksDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcbatch) as? ViewControllerBatch
            self.batchtasks = self.batchtasksDelegate?.getbatchtaskObject()
            self.outputprocess = self.batchtasks?.outputprocess
            self.process = self.batchtasks?.process
            self.batchtasks?.processTermination()
        case .quicktask:
            guard ViewControllerReference.shared.completeoperation != nil else { return }
            ViewControllerReference.shared.completeoperation!.completerunningtask(outputprocess: self.outputprocess)
            // After logging is done set reference to object = nil
            ViewControllerReference.shared.completeoperation = nil
            weak var processterminationDelegate: UpdateProgress?
            processterminationDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcquickbackup) as? ViewControllerQuickBackup
            processterminationDelegate?.processTermination()
        case .singlequicktask:
            guard self.index != nil else { return }
            self.seterrorinfo(info: "")
            self.working.stopAnimation(nil)
            self.configurations!.setCurrentDateonConfiguration(index: self.index!, outputprocess: self.outputprocess)
        case .remoteinfotask:
            guard self.configurations!.remoteinfotaskworkqueue != nil else { return }
            self.configurations!.remoteinfotaskworkqueue?.processTermination()
        case .automaticbackup:
            guard self.configurations!.remoteinfotaskworkqueue != nil else { return }
            weak var estimateupdateDelegate: Updateestimating?
            estimateupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcestimatingtasks) as? ViewControllerEstimatingTasks
            // compute alle estimates
            if self.configurations!.remoteinfotaskworkqueue!.stackoftasktobeestimated != nil {
                self.configurations!.remoteinfotaskworkqueue?.processTermination()
                estimateupdateDelegate?.updateProgressbar()
            } else {
                estimateupdateDelegate?.dismissview()
                self.configurations!.remoteinfotaskworkqueue?.processTermination()
                self.configurations!.remoteinfotaskworkqueue?.selectalltaskswithnumbers(deselect: false)
                self.configurations!.remoteinfotaskworkqueue?.setbackuplist()
                weak var openDelegate: OpenQuickBackup?
                switch ViewControllerReference.shared.activetab ?? .vctabmain {
                case .vcnewconfigurations:
                    openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcnewconfigurations) as? ViewControllerNewConfigurations
                case .vctabmain:
                    openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
                case .vccopyfiles:
                    openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vccopyfiles) as? ViewControllerCopyFiles
                case .vcloggdata:
                    openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcloggdata) as? ViewControllerLoggData
                default:
                    openDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
                }
                openDelegate?.openquickbackup()
            }
        case .rclonesize:
            self.remoteinfo(reset: false)
            self.working.stopAnimation(nil)
            self.estimating.isHidden = true
        case .restore:
            weak var processterminationDelegate: UpdateProgress?
            processterminationDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcrestore) as? ViewControllerRestore
            processterminationDelegate?.processTermination()
        case .estimatebatchtask:
            guard self.configurations!.remoteinfotaskworkqueue != nil else { return }
            weak var estimateupdateDelegate: Updateestimating?
            estimateupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcestimatingtasks) as? ViewControllerEstimatingTasks
            // compute alle estimates
            if self.configurations!.remoteinfotaskworkqueue!.stackoftasktobeestimated != nil {
                self.configurations!.remoteinfotaskworkqueue?.processTermination()
                estimateupdateDelegate?.updateProgressbar()
            } else {
                self.configurations!.remoteinfotaskworkqueue?.processTermination()
                self.configurations!.processtermination = .batchtask
            }
        }

    }

    // Function is triggered when Process outputs data in filehandler
    // Process is either in singleRun or batchRun
    func fileHandler() {
        weak var outputeverythingDelegate: ViewOutputDetails?
        if self.configurations!.processtermination == nil {
            self.configurations!.processtermination = .singlequicktask
        }
        switch self.configurations!.processtermination! {
        case .singletask:
            guard self.singletask != nil else { return }
            weak var localprocessupdateDelegate: UpdateProgress?
            localprocessupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcprogressview) as? ViewControllerProgressProcess
            self.outputprocess = self.singletask!.outputprocess
            self.process = self.singletask!.process
            localprocessupdateDelegate?.fileHandler()
            outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
            if outputeverythingDelegate?.appendnow() ?? false {
                outputeverythingDelegate?.reloadtable()
            }
        case .batchtask:
            weak var localprocessupdateDelegate: UpdateProgress?
            localprocessupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcbatch) as? ViewControllerBatch
            localprocessupdateDelegate?.fileHandler()
        case .quicktask:
            weak var localprocessupdateDelegate: UpdateProgress?
            localprocessupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcquickbackup) as? ViewControllerQuickBackup
            localprocessupdateDelegate?.fileHandler()
        case .singlequicktask:
            outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
            if outputeverythingDelegate?.appendnow() ?? false {
                outputeverythingDelegate?.reloadtable()
            }
        case .remoteinfotask:
            outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
            if outputeverythingDelegate?.appendnow() ?? false {
                outputeverythingDelegate?.reloadtable()
            }
        case .automaticbackup:
            return
        case .rclonesize:
            return
        case .restore:
            weak var localprocessupdateDelegate: UpdateProgress?
            localprocessupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcrestore) as? ViewControllerRestore
            localprocessupdateDelegate?.fileHandler()
            outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllertabMain
            if outputeverythingDelegate?.appendnow() ?? false {
                outputeverythingDelegate?.reloadtable()
            }
        case .estimatebatchtask:
            return
        }
    }
}

// Deselect a row
extension ViewControllertabMain: DeselectRowTable {
    // deselect a row after row is deleted
    func deselect() {
        guard self.index != nil else { return }
        self.mainTableView.deselectRow(self.index!)
    }
}

// If rclone throws any error
extension ViewControllertabMain: RcloneError {
    func rcloneerror() {
        // Set on or off in user configuration
        globalMainQueue.async(execute: { () -> Void in
            self.seterrorinfo(info: "Error")
            self.showrclonecommandmainview()
            self.deselect()
            // Abort any operations
            if let process = self.process {
                process.terminate()
                self.process = nil
            }
            // Either error in single task or batch task
            if self.singletask != nil {
                self.singletask!.error()
            }
            if self.batchtasks != nil {
                self.batchtasks!.error()
            }
        })
    }
}

// If, for any reason, handling files or directory throws an error
extension ViewControllertabMain: Fileerror {
    func errormessage(errorstr: String, errortype: Fileerrortype ) {
        globalMainQueue.async(execute: { () -> Void in
            if errortype == .openlogfile {
                self.rcloneCommand.stringValue = self.errordescription(errortype: errortype)
            } else if errortype == .filesize {
                self.rcloneCommand.stringValue = self.errordescription(errortype: errortype) + ": filesize = " + errorstr
            } else {
                self.seterrorinfo(info: "Error")
                self.rcloneCommand.stringValue = self.errordescription(errortype: errortype) + "\n" + errorstr
            }
        })
    }
}

// Abort task from progressview
extension ViewControllertabMain: Abort {
    // Abort any task, either single- or batch task
    func abortOperations() {
        // Terminates the running process
        if let process = self.process {
            process.terminate()
            self.index = nil
            self.working.stopAnimation(nil)
            self.process = nil
            // Create workqueu and add abort
            self.seterrorinfo(info: "Abort")
            self.rcloneCommand.stringValue = ""
            if self.configurations!.remoteinfotaskworkqueue != nil && self.configurations?.estimatedlist != nil {
                weak var localestimateupdateDelegate: Updateestimating?
                localestimateupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcestimatingtasks) as? ViewControllerEstimatingTasks
                localestimateupdateDelegate?.dismissview()
                self.configurations!.remoteinfotaskworkqueue = nil
            }
        } else {
            self.working.stopAnimation(nil)
            self.rcloneCommand.stringValue = "Selection out of range - aborting"
            self.process = nil
            self.index = nil
        }
    }
}

// Extensions from here are used in either newSingleTask or newBatchTask

extension ViewControllertabMain: StartStopProgressIndicatorSingleTask {
    func startIndicator() {
        self.working.startAnimation(nil)
        self.estimating.isHidden = false
    }

    func stopIndicator() {
        self.working.stopAnimation(nil)
        self.estimating.isHidden = true
    }
}

extension ViewControllertabMain: SingleTaskProgress {
    func gettransferredNumber() -> String {
        return ""
    }

    func gettransferredNumberSizebytes() -> String {
        return ""
    }

    func getProcessReference(process: Process) {
        self.process = process
    }

    func presentViewProgress() {
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerProgress!)
        })
    }

    func presentViewInformation(outputprocess: OutputProcess) {
        self.outputprocess = outputprocess
        if self.dynamicappend {
            globalMainQueue.async(execute: { () -> Void in
                self.mainTableView.reloadData()
            })
        } else {
            globalMainQueue.async(execute: { () -> Void in
                self.presentAsSheet(self.viewControllerInformation!)
            })
        }
    }

    func terminateProgressProcess() {
        weak var localprocessupdateDelegate: UpdateProgress?
        localprocessupdateDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcprogressview) as? ViewControllerProgressProcess
        localprocessupdateDelegate?.processTermination()
    }

    func seterrorinfo(info: String) {
        guard info != "" else {
            self.dryRunOrRealRun.isHidden = true
            return
        }
        self.dryRunOrRealRun.textColor = setcolor(nsviewcontroller: self, color: .red)
        self.dryRunOrRealRun.isHidden = false
        self.dryRunOrRealRun.stringValue = info
    }

    // Function for getting numbers out of output object updated when
    // Process object executes the job.
    func setNumbers(output: OutputProcess?) {
        globalMainQueue.async(execute: { () -> Void in
            guard output != nil else {
                self.totalNumber.stringValue = ""
                return
            }
            let number = Numbers(outputprocess: output)
            self.totalNumber.stringValue = number.stats()
        })
    }
}

extension ViewControllertabMain: GetConfigurationsObject {
    func getconfigurationsobject() -> Configurations? {
        guard self.configurations != nil else { return nil }
        return self.configurations
    }

    func createconfigurationsobject(profile: String?) -> Configurations? {
        self.configurations = nil
        self.configurations = Configurations(profile: profile)
        return self.configurations
    }

    // After a write, a reload is forced.
    func reloadconfigurationsobject() {
        // If batchtask keep configuration object
        self.batchtasks = self.batchtasksDelegate?.getbatchtaskObject()
        guard self.batchtasks == nil else {
            // Batchtask, check if task is completed
            guard self.configurations!.getbatchQueue()?.batchruniscompleted() == false else {
                self.createandreloadconfigurations()
                return
            }
            return
        }
        self.createandreloadconfigurations()
    }
}

extension ViewControllertabMain: GetSchedulesObject {
    func reloadschedulesobject() {
        // If batchtask scedules object
        guard self.batchtasks == nil else {
            // Batchtask, check if task is completed
            guard self.configurations!.getbatchQueue()?.batchruniscompleted() == false else {
                self.createandreloadschedules()
                return
            }
            return
        }
        self.createandreloadschedules()
    }

    func getschedulesobject() -> Schedules? {
        return self.schedules
    }

    func createschedulesobject(profile: String?) -> Schedules? {
        self.schedules = nil
        self.schedules = Schedules(profile: profile)
        return self.schedules
    }
}

extension ViewControllertabMain: Setinfoaboutrclone {
    internal func setinfoaboutrclone() {
        if ViewControllerReference.shared.norclone == true {
            self.info(num: 3)
        } else {
            self.info(num: 0)
            self.rcloneversionshort.stringValue = ViewControllerReference.shared.rcloneversionshort ?? ""
        }
    }
}

extension ViewControllertabMain: ErrorOutput {
    func erroroutput() {
        self.info(num: 2)
    }
}

extension ViewControllertabMain: Createandreloadconfigurations {
    // func createandreloadconfigurations()
}

extension ViewControllertabMain: Sendoutputprocessreference {
    func sendoutputprocessreference(outputprocess: OutputProcess?) {
        self.outputprocess = outputprocess
    }

    func sendprocessreference(process: Process?) {
        self.process = process
    }
}

extension  ViewControllertabMain: GetHiddenID {
    func gethiddenID() -> Int? {
        return self.hiddenID
    }
}

// New profile is loaded.
extension ViewControllertabMain: NewProfile {
    // Function is called from profiles when new or default profiles is seleceted
    func newProfile(profile: String?) {
        self.process = nil
        self.outputprocess = nil
        self.outputbatch = nil
        self.singletask = nil
        self.showrclonecommandmainview()
        self.deselect()
        // Read configurations and Scheduledata
        self.configurations = self.createconfigurationsobject(profile: profile)
        self.schedules = self.createschedulesobject(profile: profile)
        self.displayProfile()
        self.reloadtabledata()
    }

    func enableProfileMenu() {
        globalMainQueue.async(execute: { () -> Void in
            self.displayProfile()
        })
    }
}

extension ViewControllertabMain: OpenQuickBackup {
    func openquickbackup() {
        self.configurations!.processtermination = .quicktask
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerQuickBackup!)
        })
    }
}

extension ViewControllertabMain: SetRemoteInfo {
    func getremoteinfo() -> RemoteInfoTaskWorkQueue? {
        return self.configurations!.remoteinfotaskworkqueue
    }

    func setremoteinfo(remoteinfotask: RemoteInfoTaskWorkQueue?) {
        self.configurations!.remoteinfotaskworkqueue = remoteinfotask
    }
}

extension ViewControllertabMain: Count {
    func maxCount() -> Int {
        guard self.outputprocess != nil else { return 0 }
        return self.outputprocess!.getMaxcount()
    }

    func inprogressCount() -> Int {
        guard self.outputprocess != nil else { return 0 }
        return self.outputprocess!.count()
    }
}

extension ViewControllertabMain: ViewOutputDetails {
    func disableappend() {
        self.dynamicappend = false
    }

    func enableappend() {
        self.dynamicappend = true
    }

    func getalloutput() -> [String] {
        return self.outputprocess?.getrawOutput() ?? []
    }

    func reloadtable() {
        weak var localreloadDelegate: Reloadandrefresh?
        localreloadDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcalloutput) as? ViewControllerAllOutput
        localreloadDelegate?.reloadtabledata()
    }

    func appendnow() -> Bool {
        return self.dynamicappend
    }
}

extension ViewControllertabMain: AllProfileDetails {
    func disablereloadallprofiles() {
        self.allprofilesview = false
    }

    func enablereloadallprofiles() {
        self.allprofilesview = true
        self.allprofiledetailsDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vcallprofiles) as? ViewControllerAllProfiles
    }
}

enum Color {
    case red
    case white
    case green
    case black
}

protocol Setcolor: class {
    func setcolor(nsviewcontroller: NSViewController, color: Color) -> NSColor
}

extension Setcolor {

    private func isDarkMode(view: NSView) -> Bool {
        if #available(OSX 10.14, *) {
            return view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        return false
    }

    func setcolor(nsviewcontroller: NSViewController, color: Color) -> NSColor {
        let darkmode = isDarkMode(view: nsviewcontroller.view)
        switch color {
        case .red:
            return .red
        case .white:
            if darkmode {
                return .white
            } else {
                return .black
            }
        case .green:
            if darkmode {
                return .green
            } else {
                return .blue
            }
        case .black:
            if darkmode {
                return .white
            } else {
                return .black
            }
        }
    }
}
