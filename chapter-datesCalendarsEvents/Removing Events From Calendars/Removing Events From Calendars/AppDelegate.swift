//
//  AppDelegate.swift
//  Removing Events From Calendars
//
//  Created by Vandad Nahavandipoor on 6/24/14.
//  Copyright (c) 2014 Pixolity Ltd. All rights reserved.
//
//  These example codes are written for O'Reilly's iOS 8 Swift Programming Cookbook
//  If you use these solutions in your apps, you can give attribution to
//  Vandad Nahavandipoor for his work. Feel free to visit my blog
//  at http://vandadnp.wordpress.com for daily tips and tricks in Swift
//  and Objective-C and various other programming languages.
//  
//  You can purchase "iOS 8 Swift Programming Cookbook" from
//  the following URL:
//  http://shop.oreilly.com/product/0636920034254.do
//
//  If you have any questions, you can contact me directly
//  at vandad.np@gmail.com
//  Similarly, if you find an error in these sample codes, simply
//  report them to O'Reilly at the following URL:
//  http://www.oreilly.com/catalog/errata.csp?isbn=0636920034254

import UIKit
import EventKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func createEventWithTitle(
    title: String,
    startDate: NSDate,
    endDate: NSDate,
    inCalendar: EKCalendar,
    inEventStore: EKEventStore,
    notes: String) -> Bool{
      
      /* If a calendar does not allow modification of its contents
      then we cannot insert an event into it */
      if inCalendar.allowsContentModifications == false{
        print("The selected calendar does not allow modifications.")
        return false
      }
      
      /* Create an event */
      let event = EKEvent(eventStore: inEventStore)
      event.calendar = inCalendar
      
      /* Set the properties of the event such as its title,
      start date/time, end date/time, etc. */
      event.title = title
      event.notes = notes
      event.startDate = startDate
      event.endDate = endDate
      
      /* Finally, save the event into the calendar */
      var error:NSError?
      
      let result: Bool
      do {
        try inEventStore.saveEvent(event,
                span: .ThisEvent)
        result = true
      } catch let error1 as NSError {
        error = error1
        result = false
      }
      
      if result == false{
        if let theError = error{
          print("An error occurred \(theError)")
        }
      }
      
      return result
  }
  
  func sourceInEventStore(
    eventStore: EKEventStore,
    type: EKSourceType,
    title: String) -> EKSource?{
      
      for source in eventStore.sources{
        if source.sourceType.rawValue == type.rawValue &&
          source.title.caseInsensitiveCompare(title) ==
          NSComparisonResult.OrderedSame{
            return source
        }
      }
      
      return nil
  }
  
  func calendarWithTitle(
    title: String,
    type: EKCalendarType,
    source: EKSource,
    eventType: EKEntityType) -> EKCalendar?{
      
      for calendar in source.calendarsForEntityType(eventType) as Set<EKCalendar>{
        if calendar.title.caseInsensitiveCompare(title) ==
          NSComparisonResult.OrderedSame &&
          calendar.type.rawValue == type.rawValue{
            return calendar
        }
      }
      
      return nil
  }
  
  func displayAccessDenied(){
    print("Access to the event store is denied.")
  }
  
  func displayAccessRestricted(){
    print("Access to the event store is restricted.")
  }
  
  func removeEventWithTitle(
    title: String,
    startDate: NSDate,
    endDate: NSDate,
    store: EKEventStore,
    calendar: EKCalendar,
    notes: String) -> Bool{
      
      var result = false
      
      /* If a calendar does not allow modification of its contents
      then we cannot insert an event into it */
      if calendar.allowsContentModifications == false{
        print("The selected calendar does not allow modifications.")
        return false
      }
      
      let predicate = store.predicateForEventsWithStartDate(startDate,
        endDate: endDate,
        calendars: [calendar])
      
      /* Get all the events that match the parameters */
      let events = store.eventsMatchingPredicate(predicate)
        as [EKEvent]
      
      if events.count > 0{
        
        /* Delete them all */
        for event in events{
          
          do{
            try store.removeEvent(event, span: .ThisEvent, commit: false)
          } catch let error as NSError{
            print("Failed to remove \(event) with error = \(error)")
          }
        }
        
        do {
          try store.commit()
          print("Successfully committed")
          result = true
        } catch let error as NSError {
          print("Failed to commit the event store with error = \(error)")
        }
        
      } else {
        print("No events matched your input.")
      }
      
      return result
      
  }
  
  func createAndDeleteEventInStore(store: EKEventStore){
    
    let icloudSource = sourceInEventStore(store,
      type: .CalDAV,
      title: "iCloud")
    
    if icloudSource == nil{
      print("You have not configured iCloud for your device.")
      return
    }
    
    let calendar = calendarWithTitle("Calendar",
      type: .CalDAV,
      source: icloudSource!,
      eventType: .Event)
    
    if calendar == nil{
      print("Could not find the calendar we were looking for.")
      return
    }
    
    /* The event starts from today, right now */
    let startDate = NSDate()
    
    /* The end date will be 1 day from today */
    let endDate = startDate.dateByAddingTimeInterval(24 * 60 * 60)
    
    let eventTitle = "My Event"
    
    if createEventWithTitle(eventTitle,
      startDate: startDate,
      endDate: endDate,
      inCalendar: calendar!,
      inEventStore: store,
      notes: ""){
        print("Successfully created the event")
    } else {
      print("Could not create the event")
      return
    }
    
    if removeEventWithTitle(eventTitle,
      startDate: startDate,
      endDate: endDate,
      store: store,
      calendar: calendar!,
      notes: ""){
        print("Successfully created and deleted the event")
    } else {
      print("Failed to delete the event")
    }
  }
  
  func example1(){
    
    let eventStore = EKEventStore()
    
    switch EKEventStore.authorizationStatusForEntityType(.Event){
      
    case .Authorized:
      createAndDeleteEventInStore(eventStore)
    case .Denied:
      displayAccessDenied()
    case .NotDetermined:
      eventStore.requestAccessToEntityType(.Event, completion:
        {granted, error in
          if granted{
            self.createAndDeleteEventInStore(eventStore)
          } else {
            self.displayAccessDenied()
          }
        })
    case .Restricted:
      displayAccessRestricted()
    }
    
  }
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
    example1()
    self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
    // Override point for customization after application launch.
    self.window!.backgroundColor = UIColor.whiteColor()
    self.window!.makeKeyAndVisible()
    return true
  }
  
}

