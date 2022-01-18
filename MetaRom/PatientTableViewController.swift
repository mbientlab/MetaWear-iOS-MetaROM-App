//
//  PatientTableViewController.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 5/24/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
//import Parse
import RealmSwift
import BoltsSwift

class PatientTableViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let refreshControl = UIRefreshControl()
    var searchActive : Bool = false
    var allPatients: Results<Patient>!
    var visiblePatients: [Patient] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        // As the first controller, we must set up the nav bar of fun
        /*if let navigationBar = self.navigationController?.navigationBar {
            let navTitle = UIImageView(image: UIImage(named: "logo-close")!)
            let centerX = (navigationBar.frame.width / 2) - (navTitle.frame.width / 2)
            //navTitle.frame = CGRect(x: centerX, y: 0, width: navTitle.frame.width, height: navigationBar.frame.height)
            navTitle.frame = CGRect(x: centerX, y: 10, width: navTitle.frame.width, height: navigationBar.frame.height-20)
            navTitle.contentMode = .scaleAspectFit
            navigationBar.addSubview(navTitle)
        }*/
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)

        let realm = try! Realm()
        allPatients = realm.objects(Patient.self).sorted(byKeyPath: "lastSession", ascending: false)

        // Any changes to existing patients need to be sync'd to server
        NotificationToken.allPatients = allPatients.observe { [weak self] (changes: RealmCollectionChange) in
            guard let _self = self else { return }
            switch changes {
            case .initial:
                _self.doRefresh(showError: false)
                _self.searchBar(_self.searchBar, textDidChange: _self.searchBar.text ?? "")
            case .update(_, _, _, let modifications):
                modifications.forEach { i in
                    let patient = _self.allPatients[i]
                    print("Parse Syncing - \(patient.firstName)")
                    //if let patientId = patient.parseObjectId {
                        // Object in parse so we must update it
                        //let parsePatient = ParsePatient()
                        //parsePatient.objectId = patientId
                        //parsePatient.updateFrom(patient)
                        //parsePatient.saveInBackground()
                    //}
                }
            case .error( _):
                break
            }
        }

        //if !Globals.seenManualScreens {
        //    Globals.seenManualScreens = true
        //    performSegue(withIdentifier: "showSetup", sender: nil)
        //}
    }
    
    deinit {
        NotificationToken.allPatients?.invalidate()
        NotificationToken.allPatients = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchBar(searchBar, textDidChange: searchBar.text ?? "")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        refreshControl.endRefreshing()
    }
    
    @objc func refreshData(_ sender: Any) {
        doRefresh(showError: true)
    }
    
    func doRefresh(showError: Bool) {
        /*ParsePatient.syncAll().continueWith(.mainThread) { t in
            if let error = t.error {
                if showError {
                    self.showOkAlert(title: "Sync Error", message: error.localizedDescription) { _ in
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    self.refreshControl.endRefreshing()
                }
            } else {
                self.searchBar(self.searchBar, textDidChange: self.searchBar.text ?? "")
                self.refreshControl.endRefreshing()
            }
        }*/
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PatientViewController {
            destination.patient = (sender as! Patient)
        } else if let destination = segue.destination as? AddEditPatientViewController {
            destination.delegate = self
        }
    }
    
    /*@IBAction func logoutPressed(_ sender: Any) {
        PFUser.logOutInBackground()
        Globals.cachedEmail = ""
        Globals.expirationDate = Date(timeIntervalSince1970: 0)
        navigationController?.popViewController(animated: true)
    }*/
    
    @IBAction func unwindToPatientTableViewController(segue: UIStoryboardSegue) {        
    }
}

extension PatientTableViewController: AddEditPatientDelegate {
    func controller(_ controller: AddEditPatientViewController, didAddPatient patient: Patient) {
        doRefresh(showError: false)
        searchBar(searchBar, textDidChange: searchBar.text ?? "")
        dismiss(animated: true)
    }
    func controller(_ controller: AddEditPatientViewController, didEditPatient patient: Patient) {
        doRefresh(showError: false)
        dismiss(animated: true)
    }
    func controllerDidCancel(_ controller: AddEditPatientViewController) {
        dismiss(animated: true)
    }
}

extension PatientTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        visiblePatients = searchText.isEmpty ? allPatients.map { $0 } : allPatients.filter {
            $0.searchString.localizedCaseInsensitiveContains(searchText)
        }
        tableView.reloadData()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        self.searchBar(searchBar, textDidChange: "")
        searchBar.resignFirstResponder()
    }
}

extension PatientTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visiblePatients.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row != 0 else {
            return tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "PatientCell", for: indexPath) as! PatientTableViewCell
        let cur = visiblePatients[indexPath.row - 1]
        cell.patientId.text = cur.patientID
        cell.name.text = cur.firstName + " " + cur.lastName
        cell.lastSession.text = cur.lastSession?.timeAgo() ?? "N/A"
        return cell
    }
}

extension PatientTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row != 0 else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: false)
        performSegue(withIdentifier: "ShowPatient", sender: visiblePatients[indexPath.row - 1])
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete \(visiblePatients[indexPath.row - 1].fullName)?  This removes all of their data and cannot be undone.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                let cur = self.visiblePatients.remove(at: indexPath.row - 1)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                cur.delete()
                let _ = DeleteOp.deleteAll()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // Support display in iPad
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            alert.popoverPresentationController?.permittedArrowDirections = []
            
            present(alert, animated: true)
        }
    }
}
