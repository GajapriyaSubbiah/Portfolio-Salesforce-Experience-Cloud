public with sharing class OpportunityTriggerHandler {

    // After insert: add Opportunity.Amount to the related Account.AnnualRevenue
    public static void afterInsert(List<Opportunity> newOpps) {
        Map<Id, Decimal> accDelta = new Map<Id, Decimal>();
        for (Opportunity o : newOpps) {
            if (o.AccountId != null && o.Amount != null) {
                if (!accDelta.containsKey(o.AccountId)) accDelta.put(o.AccountId, o.Amount);
                else accDelta.put(o.AccountId, accDelta.get(o.AccountId) + o.Amount);
            }
        }
        applyAccountDeltas(accDelta);
    }

    // After update: apply the difference (new - old) and handle AccountId changes
    public static void afterUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        Map<Id, Decimal> accDelta = new Map<Id, Decimal>();
        for (Opportunity o : newOpps) {
            Opportunity oldOpp = oldMap.get(o.Id);
            Decimal oldAmt = (oldOpp.Amount == null) ? 0 : oldOpp.Amount;
            Decimal newAmt = (o.Amount == null) ? 0 : o.Amount;
            Id oldAcc = oldOpp.AccountId;
            Id newAcc = o.AccountId;

            if (oldAcc == newAcc) {
                if (newAcc != null) {
                    Decimal diff = newAmt - oldAmt;
                    if (diff != 0) accDelta.put(newAcc, (accDelta.containsKey(newAcc) ? accDelta.get(newAcc) : 0) + diff);
                }
            } else {
                // subtract from old account
                if (oldAcc != null && oldAmt != 0) {
                    accDelta.put(oldAcc, (accDelta.containsKey(oldAcc) ? accDelta.get(oldAcc) : 0) - oldAmt);
                }
                // add to new account
                if (newAcc != null && newAmt != 0) {
                    accDelta.put(newAcc, (accDelta.containsKey(newAcc) ? accDelta.get(newAcc) : 0) + newAmt);
                }
            }
        }
        applyAccountDeltas(accDelta);
    }

    // After delete: subtract deleted Opportunity amounts from the related Account
    public static void afterDelete(List<Opportunity> oldOpps) {
        Map<Id, Decimal> accDelta = new Map<Id, Decimal>();
        for (Opportunity o : oldOpps) {
            if (o.AccountId != null && o.Amount != null) {
                accDelta.put(o.AccountId, (accDelta.containsKey(o.AccountId) ? accDelta.get(o.AccountId) : 0) - o.Amount);
            }
        }
        applyAccountDeltas(accDelta);
    }

    // Helper to apply accumulated deltas to Account.AnnualRevenue
    private static void applyAccountDeltas(Map<Id, Decimal> accDelta) {
        if (accDelta.isEmpty()) return;
        List<Account> accounts = [SELECT Id, AnnualRevenue FROM Account WHERE Id IN :accDelta.keySet() FOR UPDATE];
        List<Account> toUpdate = new List<Account>();
        for (Account a : accounts) {
            Decimal delta = accDelta.get(a.Id);
            Decimal current = (a.AnnualRevenue == null) ? 0 : a.AnnualRevenue;
            a.AnnualRevenue = current + delta;
            toUpdate.add(a);
        }
        if (!toUpdate.isEmpty()) update toUpdate;
    }

}
