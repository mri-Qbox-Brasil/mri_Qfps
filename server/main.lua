if GetResourceState('mri_Qbox') ~= 'started' then
    lib.addCommand('fpsmenu',{
        help = locale('menu.description'),
    }, function(source, args, raw)
        lib.callback('mri_Qfps:fpsMenu', source)
    end)
end
