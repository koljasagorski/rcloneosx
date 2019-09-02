//
//  ViewControllerAllProfiles.swift
//  rcloneOSX
//
//  Created by Thomas Evensen on 07.03.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import Cocoa

protocol ReloadTableAllProfiles: class {
    func reloadtable()
}

class ViewControllerAllProfiles: NSViewController, Delay {

    // Main tableview
    @IBOutlet weak var mainTableView: NSTableView!
    @IBOutlet weak var search: NSSearchField!
    @IBOutlet weak var sortdirection: NSButton!
    @IBOutlet weak var numberOfprofiles: NSTextField!

    private var allprofiles: AllConfigurations?
    private var column: Int?
    private var filterby: Sortandfilter?
    private var sortascending: Bool = true

    weak var allprofiledetailsdelegata: AllProfileDetails?

    @IBAction func sortdirection(_ sender: NSButton) {
        if self.sortascending == true {
            self.sortascending = false
            self.sortdirection.image = #imageLiteral(resourceName: "down")
        } else {
            self.sortascending = true
            self.sortdirection.image = #imageLiteral(resourceName: "up")
        }
        guard self.filterby != nil else { return }
        switch self.filterby! {
        case .executedate:
            self.allprofiles?.allconfigurationsasdictionary = self.allprofiles!.sortbydate(notsortedlist: self.allprofiles?.allconfigurationsasdictionary, sortdirection: self.sortascending)
        default:
            self.allprofiles?.allconfigurationsasdictionary = self.allprofiles!.sortbystring(notsortedlist: self.allprofiles?.allconfigurationsasdictionary, sortby: self.filterby!, sortdirection: self.sortascending)
        }
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setting delegates and datasource
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        self.search.delegate = self
        ViewControllerReference.shared.setvcref(viewcontroller: .vcallprofiles, nsviewcontroller: self)
        self.sortdirection.image = #imageLiteral(resourceName: "up")
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.reloadallprofiles()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcallprofiles, nsviewcontroller: self)
        self.allprofiledetailsdelegata = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        self.allprofiledetailsdelegata?.enablereloadallprofiles()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.allprofiledetailsdelegata?.disablereloadallprofiles()
    }

    private func reloadallprofiles() {
        self.allprofiles = AllConfigurations()
        self.sortascending = true
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }
}

extension ViewControllerAllProfiles: NSTableViewDataSource {
    // Delegate for size of table
    func numberOfRows(in tableView: NSTableView) -> Int {
        if self.allprofiles?.allconfigurationsasdictionary == nil {
            self.numberOfprofiles.stringValue = "Number of configurations:"
            return 0
        } else {
            self.numberOfprofiles.stringValue = "Number of configurations: " +
                String(self.allprofiles!.allconfigurationsasdictionary?.count ?? 0)
            return self.allprofiles!.allconfigurationsasdictionary?.count ?? 0
        }
    }
}

extension ViewControllerAllProfiles: NSTableViewDelegate, Attributedestring {

    // TableView delegates
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if row > self.allprofiles!.allconfigurationsasdictionary!.count - 1 { return nil }
        let object: NSDictionary = self.allprofiles!.allconfigurationsasdictionary![row]
        return object[tableColumn!.identifier] as? String
    }
    // setting which table row is selected
    func tableViewSelectionDidChange(_ notification: Notification) {
        let myTableViewFromNotification = (notification.object as? NSTableView)!
        let column = myTableViewFromNotification.selectedColumn
        var sortbystring = true
        self.column = column
        switch column {
        case 0:
            self.filterby = .profile
        case 1:
            self.filterby = .task
        case 2:
            self.filterby = .localcatalog
        case 3:
            self.filterby = .offsitecatalog
        case 4:
            self.filterby = .offsiteserver
        case 5:
            self.filterby = .backupid
        case 6, 7:
            sortbystring = false
            self.filterby = .executedate
        default:
            return
        }
        if sortbystring {
            self.allprofiles?.allconfigurationsasdictionary = self.allprofiles!.sortbystring(notsortedlist: self.allprofiles?.allconfigurationsasdictionary, sortby: self.filterby!, sortdirection: self.sortascending)
        } else {
            self.allprofiles?.allconfigurationsasdictionary = self.allprofiles!.sortbydate(notsortedlist: self.allprofiles?.allconfigurationsasdictionary, sortdirection: self.sortascending)
        }
        globalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }
}

extension ViewControllerAllProfiles: NSSearchFieldDelegate {

    func controlTextDidChange(_ obj: Notification) {
        self.delayWithSeconds(0.25) {
            guard self.column != nil else { return }
            let filterstring = self.search.stringValue
            if filterstring.isEmpty {
                globalMainQueue.async(execute: { () -> Void in
                    self.allprofiles = AllConfigurations()
                    self.mainTableView.reloadData()
                })
            } else {
                globalMainQueue.async(execute: { () -> Void in
                    self.allprofiles?.myownfilter(search: filterstring, filterby: self.filterby)
                    self.mainTableView.reloadData()
                })
            }
        }
    }

    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        globalMainQueue.async(execute: { () -> Void in
            self.allprofiles = AllConfigurations()
            self.mainTableView.reloadData()
        })
    }
}

extension ViewControllerAllProfiles: ReloadTableAllProfiles {
    func reloadtable() {
        self.reloadallprofiles()
    }
}
