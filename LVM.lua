---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type LVM
local LVM = {

    __type__ = 'LVM',

    debug = require 'lvm/debug',
    constants = require 'lvm/constants',
    flags = require 'lvm/flags',
    print = require 'lvm/print',
    type = require 'lvm/type',
    scope = require 'lvm/scope',
    audit = require 'lvm/audit',
    package = require 'lvm/package',
    generic = require 'lvm/generic',
    meta = require 'lvm/meta',
    stack = require 'lvm/stack',
    super = require 'lvm/super',
    field = require 'lvm/field',
    parameter = require 'lvm/parameter',
    constructor = require 'lvm/constructor',
    method = require 'lvm/method',
    class = require 'lvm/class'
};

LVM.debug.setLVM(LVM);
LVM.constants.setLVM(LVM);
LVM.flags.setLVM(LVM);
LVM.print.setLVM(LVM);
LVM.type.setLVM(LVM);
LVM.scope.setLVM(LVM);
LVM.audit.setLVM(LVM);
LVM.package.setLVM(LVM);
LVM.generic.setLVM(LVM);
LVM.meta.setLVM(LVM);
LVM.stack.setLVM(LVM);
LVM.super.setLVM(LVM);
LVM.field.setLVM(LVM);
LVM.parameter.setLVM(LVM);
LVM.constructor.setLVM(LVM);
LVM.method.setLVM(LVM);
LVM.class.setLVM(LVM);

return LVM;
