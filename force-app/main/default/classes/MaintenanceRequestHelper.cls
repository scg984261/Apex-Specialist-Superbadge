public with sharing class MaintenanceRequestHelper {
    
    public static void updateWorkOrders(List<Case> maintenanceRequests) {

        // List of new Maintenance Requests to Insert.
        List<Case> maintenanceRequestsToInsert = new List<Case>();

        // List of new maintenance items to insert.   
        List<Equipment_Maintenance_Item__c> equipmentMaintenanceItemsToInsert = new List<Equipment_Maintenance_Item__c>();

        // Map between old case Ids (Ids which fired the trigger), and the new case object to be inserted.
        Map<Id,Case> caseMap = new Map<Id,Case>();
        
        // Loop through cases and add all the Ids to a set.
        Set<Id> maintenanceRequestIds = new Set<Id>();
        
        for(Case c : maintenanceRequests) {
            maintenanceRequestIds.add(c.Id);
        }

        // Use the set of Ids to filter a query to get the related Equipment Maintenance Items.
        Map<Id,Equipment_Maintenance_Item__c> emiMap = new Map<Id,Equipment_Maintenance_Item__c>([
            SELECT Id, Equipment__c, Maintenance_Request__c, Equipment__r.Maintenance_Cycle__c
            FROM   Equipment_Maintenance_Item__c
            WHERE  Maintenance_Request__c IN :maintenanceRequestIds
        ]);
        
        // Loop through the all the cases.
        for(Case mr : maintenanceRequests) {
            if(mr.Status == 'Closed' && (mr.Type == 'Routine Maintenance' || mr.Type == 'Repair')) {                 
                Decimal shortestCycle = 0;
                
                // Loop through the Equipment maintenance items.
                for(Id key : emiMap.keySet()) {
                    // Find whether this Equipment maintenance item belongs to this Case.
                    if(emiMap.get(key).Maintenance_Request__c == mr.Id) {
                        // Get the number of days in the maintenance cycle.
                        Decimal maintenanceCycle = emiMap.get(key).Equipment__r.Maintenance_Cycle__c;
                        
                        // Get the shortest maintenance cycle.
                        if(maintenanceCycle < shortestCycle || shortestCycle == 0) {
                            shortestCycle = maintenanceCycle;
                        }
                    }
                }
                             
                // Create the new Request.
                Case newMaintenanceRequest = new Case(
                    ParentId=mr.ParentId,
                    Type='Routine Maintenance',
                    Subject='New Routine Maintenance Request',
                    Date_Reported__c=System.Today(),
                    Date_Due__c=System.Today().addDays((Integer) shortestCycle),
                    Vehicle__c=mr.Vehicle__c,
                    Origin='Web'
                );

                maintenanceRequestsToInsert.add(newMaintenanceRequest);

                // Map the old case which triggered this method to the new Case which has just been created.
                caseMap.put(mr.Id, newMaintenanceRequest);
            }
        }
        
        // INSERT the new maintenance requests so that they now have Unique Ids.
        if(maintenanceRequestsToInsert.size() > 0) {
            INSERT maintenanceRequestsToInsert;
        }
        
        // Now iterating through the map (Id of old Maintenance record to the new Maintenance record)
        for(Id key : caseMap.keySet()) {
            for(Id emiKey : emiMap.keySet()) {
                // If the key (Id of the old case) matches the Maintenance Request of the Eqipment Maintenance Item, create a new one.
                if(key == emiMap.get(emiKey).Maintenance_Request__c) {
                    Equipment_Maintenance_Item__c emi = new Equipment_Maintenance_Item__c(
                        Equipment__c=emiMap.get(emiKey).Equipment__c,
                        Maintenance_Request__c=caseMap.get(key).Id
                    );
                    
                    equipmentMaintenanceItemsToInsert.add(emi);
                }                
            }
        }
        
        if(equipmentMaintenanceItemsToInsert.size() > 0) {
            INSERT equipmentMaintenanceItemsToInsert;
        }
    }        
}