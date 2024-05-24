- [Adjust live processing DaVis-MATLAB interface](#adjust-live-processing-davis-matlab-interface)
- [Adjust looping measurement DaVis-MATLAB interface](#adjust-looping-measurement-davis-matlab-interface)
- [PIV postprocessing settings](#piv-postprocessing-settings)
- [Looping measurement settings](#looping-measurement-settings)


### Adjust live processing DaVis-MATLAB interface
1. Launch `DaVis` and go to `Recording`
    
    ![image](./media/davis-recording.PNG)
2. Select `Aria of Intereset`
    
    ![image](./media/davis-recording-aoi.PNG)
3. Config crop frame and accept changes
    
    ![image](./media/davis-aoi.PNG)
4. Enable `live processing`
    
    ![image](./media/davis-recording-live-processing.PNG)
5. Enable `live view`
    
    ![image](./media/davis-recording-live-view.PNG)
6. Go to `configure processing`
    
    ![image](./media/davis-recording-configure-processing.PNG)
7. Import `operation list` located in `./macros/2DPIV-LIVE-MATLAB.OperationList.lvs`
    
    ![image](./media/davis-recording-configure-processing-import.PNG)
8. Adjust PIV settings
    
    ![image](./media/davis-recording-configure-processing-piv.png)
9. Configure script:
   1. Redefine `dll_name` varibale by absolute path of `libs\sock\sock_cl.dll`
   2. Redefine `parsInt` and `parsString` variables by actual MATLAB TCP server port and address

   ![image](./media/davis-recording-configure-processing-cl.png) 
10. Return to `Recording` and enable `live view`
11. Go to MATLAB application and adjust postprocessing ([see more](#piv-postprocessing-settings))

    ![image](./media/applab-piv.png)


### Adjust looping measurement DaVis-MATLAB interface
1. Launch `DaVis` and go to `Recording` 
    
    ![image](./media/davis-recording.PNG)
2. Import `setting list` located in `macros\PIV-LOOP-MATLAB.Recording.lvs` 
    
    ![image](./media/davis-recording-settings-import.PNG)
3. Configure script:
   1. Redefine `dll_name` varibale by absolute path of `libs\sock\sock_cl.dll`
   2. Redefine `parsInt` and `parsString` variables by actual MATLAB TCP server port and address

   ![image](./media/davis-recording-settings-cl.PNG)
4. Adjust measurements parameters
    
    ![image](./media/davis-recording-settings-adjust.PNG)
5. Go to MATLAB application, switch to `MES` tab and configure measurement grid ([see more](#looping-measurement-settings)) then click to `Start` button
    
    ![image](./media/applab-mes.png)

6. Go to DaVis and click `Recording` button
   
   ![image](./media/davis-recording-start.PNG)


### PIV postprocessing settings

| name        | description                                                                   |
| :---------- | :---------------------------------------------------------------------------- |
| port        | MATLAB TCP server port                                                        |
| statistics  | measurement count                                                             |
| fill        | fill missing value algorithm applying to instantaneous data                   |
| spatfilt    | spatial filter applying to time averaged data                                 |
| spatfiltker | kernel size of `spatfilt` transform                                           |
| shift       | perform transversal pixel shifting of 2D data before longitudinal averaging   |
| shiftker    | kernel of `shift` transform: `[left upper corner, right upper corner, width]` |
| subtrend    | subtract trend from 1D data                                                   |
| tukerwin    | weight 1D data by window function                                             |

### Looping measurement settings

| name       | description                                                                         |
| :--------- | :---------------------------------------------------------------------------------- |
| port       | MATLAB TCP server port                                                              |
| index      | channel of actuator position                                                        |
| voltage    | voltage vector                                                                      |
| position   | step motors position vector                                                         |
| amplitude  | voltage vector to assign same amplitude for all channels                            |
| seeding    | apply flow seeding during measurement                                               |
| triggerpin | external trigger pin of MCU board to synchronize DaVis recording                    |
| grid       | scan table building mode: <br>1. manual<br>2. generator                             |
| mode       | measurement mode:<br>1. extsync - DaVis store data<br>2. matlab - MATLAB store data |