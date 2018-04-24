primitive DriverLines
    fun apply(delegate: DriverBuffered tag): DriverBytes tag =>
        DriverSplitBy(delegate, "\n")
