public with sharing class WarehouseSyncSchedule implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        Id jobId = System.enqueueJob(new WarehouseCalloutService());
    }
    
}