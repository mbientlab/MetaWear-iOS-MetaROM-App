//
//  PatientViewController.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 5/24/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

import UIKit
import Charts
import RealmSwift

class PatientViewController: UIViewController {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastSessionLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let refreshControl = UIRefreshControl()
    var patient: Patient!
    var allSessions: Results<Session>!
    
    let shareTextLabel = UILabel()
    var selectedSessions: [Session] = []
    var sharing: Bool = false {
        didSet {
            collectionView?.allowsMultipleSelection = sharing
            collectionView?.selectItem(at: nil, animated: true, scrollPosition: UICollectionView.ScrollPosition())
            selectedSessions.removeAll(keepingCapacity: false)
            guard let shareButton = self.navigationItem.rightBarButtonItems?.first else {
                return
            }
            guard sharing else {
                navigationItem.setRightBarButtonItems([shareButton], animated: true)
                return
            }
            updateSharedSessionCount()
            let sharingDetailItem = UIBarButtonItem(customView: shareTextLabel)
            navigationItem.setRightBarButtonItems([shareButton, sharingDetailItem], animated: true)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        
        let realm = try! Realm()
        allSessions = realm.objects(Session.self).filter("patient == %@", patient!).sorted(byKeyPath: "started", ascending: false)
        
        // Refresh once on loading
        doRefresh(showError: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nameLabel.text = patient.fullName
        lastSessionLabel.text = patient.lastSession == nil ? "N/A" : DateFormatter.localizedString(from: patient.lastSession!, dateStyle: .short, timeStyle: .none)
        //ageLabel.text = patient.dateOfBirth == nil ? "N/A" : "\(Calendar.current.dateComponents([Calendar.Component.year], from: patient.dateOfBirth!, to: Date()).year!)"
        //heightLabel.text = patient.heightCm.value == nil ? "N/A" : "\(patient.heightCm.value!) cm"
        //weightLabel.text = patient.weightKg.value == nil ? "N/A" : "\(patient.weightKg.value!) kg"
        //targetLabel.text = patient.injury ?? "N/A"
        
        collectionView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        refreshControl.endRefreshing()
    }
    
    @objc func refreshData(_ sender: Any) {
        doRefresh(showError: true)
    }
    
    func doRefresh(showError: Bool) {
        /*ParseSession.syncAllFor(patient).continueWith(.mainThread) { t in
            if let error = t.error {
                if showError {
                    self.showOkAlert(title: "Sync Error", message: error.localizedDescription) { _ in
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    self.refreshControl.endRefreshing()
                }
            } else {
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }*/
    }
    
    func updateSharedSessionCount() {
        shareTextLabel.textColor = .white
        shareTextLabel.text = "\(selectedSessions.count) session\(selectedSessions.count > 1 ? "s" : "") selected"
        shareTextLabel.sizeToFit()
    }
    
    // TODO: Add a share bar button item hooked up to this
    @IBAction func share(_ sender: UIBarButtonItem) {
        guard !selectedSessions.isEmpty else {
            sharing = !sharing
            return
        }
        guard sharing else  {
            return
        }
        sender.isEnabled = false
        let urls = selectedSessions.map { $0.zipFileURL }
        // The UIActivityViewController taks a long time to setup so we do this on a background thread
        DispatchQueue.global().async {
            let activity = UIActivityViewController(activityItems: urls, applicationActivities: nil)
            activity.completionWithItemsHandler = { (activity, success, items, error) in
                self.sharing = false
            }
            DispatchQueue.main.async {
                sender.isEnabled = true
                activity.popoverPresentationController?.barButtonItem = sender
                self.present(activity, animated: true)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SessionSetupViewController {
            destination.patient = patient
            destination.sessionNumber = allSessions.count + 1
        } else if let destination = segue.destination as? SingleSessionViewController {
            let idx = sender as! Int
            destination.session = allSessions[idx]
            destination.sessionNumber = allSessions.count - idx
        } else if let destination = segue.destination as? AddEditPatientViewController {
            destination.patient = patient
            destination.delegate = self
        }
    }
    
    @IBAction func unwindToPatientViewController(segue: UIStoryboardSegue) {
        
    }
}

extension PatientViewController: AddEditPatientDelegate {
    func controller(_ controller: AddEditPatientViewController, didAddPatient patient: Patient) {
        dismiss(animated: true)
    }
    func controller(_ controller: AddEditPatientViewController, didEditPatient patient: Patient) {
        dismiss(animated: true)
    }
    func controllerDidCancel(_ controller: AddEditPatientViewController) {
        dismiss(animated: true)
    }
}

extension PatientViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if sharing {
            let session = allSessions[indexPath.row]
            selectedSessions.append(session)
            updateSharedSessionCount()
        } else {
            collectionView.deselectItem(at: indexPath, animated: false)
            performSegue(withIdentifier: "ShowSingleSession", sender: indexPath.row)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard sharing else {
            return
        }
        let session = allSessions[indexPath.row]
        
        if let index = selectedSessions.firstIndex(of: session) {
            selectedSessions.remove(at: index)
            updateSharedSessionCount()
        }
    }
}

extension PatientViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allSessions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SessionCell", for: indexPath) as! SessionCollectionViewCell
        cell.session = allSessions[indexPath.row]
        cell.sessionNumber = allSessions.count - indexPath.row
        cell.updateUI()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SessionHistoryCell", for: indexPath) as! SessionHistoryCollectionReusableView
            view.allSessions = allSessions.reversed().map { $0 }
            view.updateUI()
            return view
        }
        fatalError("Unexpected kind")
    }
}
