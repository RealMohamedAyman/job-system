addEvent("boxes:pay", true)
addEventHandler("boxes:pay", root, function(amount)
    exports.global:giveMoney(source, amount)
end)