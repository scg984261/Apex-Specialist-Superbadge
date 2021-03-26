public with sharing class WarehouseCalloutService implements Queueable {

    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';
	
	@future(callout=true)    
    public static void updateEquipmentHttpRequest () {
        List<Product2> newEquipment = new List<Product2>();
        List<Product2> equipmentToUpdate = new List<Product2>();
        List<Product2> equipmentToInsert = new List<Product2>();
        
     	Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        
        List<Object> equipmentList = new List<Object>();
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
            equipmentList = (List<Object>) JSON.deserializeUntyped(response.getBody());
            
            for(Object itemOfEquipment : equipmentList) {
                Map<String,Object> item = (Map<String,Object>) itemOfEquipment;
                
                Product2 product = new Product2(       
                    Name=(String) item.get('name'),            
                    Replacement_Part__c=true,
                    Current_Inventory__c=(Integer) item.get('quantity'),
                    Maintenance_Cycle__c=(Integer) item.get('maintenanceperiod'),
                    Lifespan_Months__c=(Integer) item.get('lifespan'),
                    Cost__c=(Decimal) item.get('cost'),
                    Warehouse_SKU__c=(String) item.get('sku')
                );
                
                newEquipment.add(product);
            }
        }
        
       List<Product2> oldProducts = [
            SELECT Id, Replacement_Part__c, Current_Inventory__c, Maintenance_Cycle__c, Lifespan_Months__c, Cost__c, Warehouse_SKU__c, ExternalId, ProductCode
            FROM   Product2
        ];

        boolean matchFound = false;

        for(Product2 newProd : newEquipment) {
            matchFound = false;
            for(Product2 oldProd : oldProducts) {
                if(oldProd.Warehouse_SKU__c == newProd.Warehouse_SKU__c) {
                    matchFound = true;

                    oldProd.name = newProd.name;
                    oldProd.Replacement_Part__c = newProd.replacement_Part__c;
                    oldProd.Current_Inventory__c = newProd.Current_Inventory__c;
                    oldProd.Maintenance_Cycle__c = newProd.Maintenance_Cycle__c;
                    oldProd.Lifespan_Months__c = newProd.Lifespan_Months__c;
                    oldProd.Cost__c = newProd.Cost__c;

                    equipmentToUpdate.add(oldProd);
                }
            }

            if(!matchFound) {
                equipmentToInsert.add(newProd);
            }
        }

        // DELETE the records in the table which were already wrongly added.
        if(equipmentToInsert.size() > 0) {
            INSERT equipmentToInsert;
        }

        if(equipmentToUpdate.size() > 0) {
            UPDATE equipmentToUpdate;
        }

        System.debug(equipmentToUpdate.size() + ' ROWS UPDATED');
        System.debug(equipmentToInsert.size() + ' ROWS INSERTED');
    }
    
    public void execute(QueueableContext context) {
        WarehouseCalloutService.updateEquipmentHttpRequest();
    }
}