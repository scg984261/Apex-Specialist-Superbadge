@isTest
public with sharing class MaintenanceRequestHelperTest {
    // implement scheduled code here
   	
    @TestSetup
    static void setup() {
        Vehicle__c v = new Vehicle__c(
            Name='Pop-Up Camper'
        );

        INSERT v;

        Case c = new Case(
            Status='New',
            Origin='Web',
            Vehicle__c=v.Id,
            Type='Routine Maintenance'
        );

        INSERT c;
        System.debug(c.Id);

        Product2 prod = new Product2(Name='Test Product', Replacement_Part__c=true, Maintenance_Cycle__c=5);
        INSERT prod;
        System.debug(prod.Id);

        Equipment_Maintenance_Item__c emi = new Equipment_Maintenance_Item__c(Equipment__c=prod.Id, Maintenance_Request__c=c.Id);
        INSERT emi;
    }

    @isTest
    static void test() {
        
        Case c = [
            SELECT Id, Status, Origin, Vehicle__c, Type
            FROM   Case
            LIMIT  1
        ];

        Product2 prod = [
            SELECT Id, Name
            FROM   Product2
            LIMIT  1
        ];

        Equipment_Maintenance_Item__c emi = [
            SELECT Id, Name, Equipment__c, Maintenance_Request__c
            FROM   Equipment_Maintenance_Item__c
            LIMIT  1
        ];

        Test.StartTest();
        c.Status='Closed';
        UPDATE c;
                
        // Test that all the fields have been auto-populated.
        System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Id != :c.Id AND Vehicle__c =:c.Vehicle__c AND Subject=:'New Routine Maintenance Request' AND Date_Reported__c=:System.Today() AND Date_Due__c=:System.Today().addDays(5)]);
        
        Case newCase = [
            SELECT Id
            FROM Case
            WHERE Id != :c.Id
            AND Vehicle__c =:c.Vehicle__c
            AND Subject=:'New Routine Maintenance Request'
            AND Date_Reported__c=:System.Today()
            AND Date_Due__c=:System.Today().addDays(5)
            LIMIT 1
        ];
        
        // Test that the new Equipment Maintenance Item has been correctly inserted.
        System.AssertEquals(1, [SELECT COUNT() FROM Equipment_Maintenance_Item__c WHERE Equipment__c=:prod.Id AND Maintenance_Request__c=:newCase.Id]);
        
        Test.StopTest();
    }
}