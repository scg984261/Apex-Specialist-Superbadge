@isTest
public with sharing class WarehouseSyncScheduleTest {
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    
    // implement scheduled code here
    @isTest
    public static void testWarehouseSyncSchedule() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new WarehouseSyncSchedule());
        Test.stopTest();
        
        System.assertEquals(1, [SELECT count() FROM Product2]);
    }
}