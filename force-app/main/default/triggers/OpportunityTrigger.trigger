trigger OpportunityTrigger on Opportunity (after insert, after update, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OpportunityTriggerHandler.afterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            OpportunityTriggerHandler.afterDelete(Trigger.old);
        }
    }
}
