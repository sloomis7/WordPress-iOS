import Foundation
import WordPressShared


/// In this Extension, we'll enhance NotificationsViewController, so that it supports *Swipeable* rows.
/// On the first iteration, we'll only support Comment Actions (matching the Push Interactive Notifications
/// actionable items).
///
extension NotificationsViewController
{
    // MARK: - UITableViewDelegate Methods
    
    public override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard let note = tableViewHandler.resultsController.objectAtIndexPath(indexPath) as? Notification else {
            return false
        }
        
        return note.isComment
    }
    
    public override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    public override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        guard let note = tableViewHandler.resultsController.objectAtIndexPath(indexPath) as? Notification,
                    group = note.blockGroupOfType(NoteBlockGroupType.Comment),
                    block = group.blockOfType(.Comment) else {
            return nil
        }
        
        // Helpers
        let isTrashEnabled      = block.isActionEnabled(NoteActionTrashKey)
        let isApproveEnabled    = block.isActionEnabled(NoteActionApproveKey)
        let isApproveOn         = block.isActionOn(NoteActionApproveKey)
        var actions             = [UITableViewRowAction]()
        
        // Comments: Trash
        if isTrashEnabled {
            let title = NSLocalizedString("Trash", comment: "Trashes a comment")
            
            let trash = UITableViewRowAction(style: .Destructive, title: title, handler: { [weak self] action, path in
                self?.showUndeleteForNoteWithID(note.objectID) { completion in
                    self?.trashCommentWithBlock(block) { success in
                        completion(success)
                    }
                }
                
                self?.tableView.setEditing(false, animated: true)
            })
            
            trash.backgroundColor = WPStyleGuide.errorRed()
            actions.append(trash)
        }
        
        // Comments: Unapprove
        if isApproveEnabled && isApproveOn {
            let title = NSLocalizedString("Unapprove", comment: "Unapproves a Comment")
            
            let trash = UITableViewRowAction(style: .Normal, title: title, handler: { [weak self] action, path in
                self?.unapproveCommentWithBlock(block)
                self?.tableView.setEditing(false, animated: true)
            })
            
            trash.backgroundColor = WPStyleGuide.grey()
            actions.append(trash)
        }

        // Comments: Approve
        if isApproveEnabled && !isApproveOn {
            let title = NSLocalizedString("Approve", comment: "Approves a Comment")
            
            let trash = UITableViewRowAction(style: .Normal, title: title, handler: { [weak self] action, path in
                self?.approveCommentWithBlock(block)
                self?.tableView.setEditing(false, animated: true)
            })
            
            trash.backgroundColor = WPStyleGuide.wordPressBlue()
            actions.append(trash)
        }
        
        return actions
    }
    
    
    
    // MARK: - Private Helpers
    
    /// Trashes a comment referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block:        The Notification's Comment Block
    ///     - completion:   Closure block to be executed on completion
    ///
    private func trashCommentWithBlock(block: NotificationBlock, completion: ((success: Bool) -> ())? = nil) {
        let context = ContextManager.sharedInstance().mainContext
        let service = CommentService(managedObjectContext: context)
        
        service.deleteCommentWithID(block.metaCommentID, siteID: block.metaSiteID, success: {
            DDLogSwift.logInfo("Successfully deleted comment \(block.metaSiteID).\(block.metaCommentID)")
            completion?(success: true)
        },
        failure: { error in
            DDLogSwift.logInfo("Error while trying to delete comment: \(error)")
            completion?(success: false)
        })
    }
    
    
    /// Approves a comment referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block:        The Notification's Comment Block
    ///     - completion:   Closure block to be executed on completion
    ///
    private func approveCommentWithBlock(block: NotificationBlock, completion: ((success: Bool) -> ())? = nil) {
        let context = ContextManager.sharedInstance().mainContext
        let service = CommentService(managedObjectContext: context)
        
        service.approveCommentWithID(block.metaCommentID, siteID: block.metaSiteID, success: {
            DDLogSwift.logInfo("Successfully approved comment \(block.metaSiteID).\(block.metaCommentID)")
            completion?(success: true)
        },
        failure: { error in
            DDLogSwift.logInfo("Error while trying to moderate comment: \(error)")
            block.removeActionOverrideForKey(NoteActionApproveKey)
            completion?(success: false)
        })
        
        block.setActionOverrideValue(true, forKey: NoteActionApproveKey)
    }
    
    
    /// Unapproves a comment referenced by a given NotificationBlock.
    ///
    /// - Parameters:
    ///     - block:        The Notification's Comment Block
    ///     - completion:   Closure block to be executed on completion
    ///
    private func unapproveCommentWithBlock(block: NotificationBlock, completion: ((success: Bool) -> ())? = nil) {
        let context = ContextManager.sharedInstance().mainContext
        let service = CommentService(managedObjectContext: context)
        
        service.unapproveCommentWithID(block.metaCommentID, siteID: block.metaSiteID, success: {
            DDLogSwift.logInfo("Successfully unapproved comment \(block.metaSiteID).\(block.metaCommentID)")
            completion?(success: true)
        },
        failure: { error in
            DDLogSwift.logInfo("Error while trying to moderate comment: \(error)")
            block.removeActionOverrideForKey(NoteActionApproveKey)
            completion?(success: false)
        })
        
        block.setActionOverrideValue(false, forKey: NoteActionApproveKey)
    }
}
