package edu.ohsu.dmice.cmp.htn;

import edu.ohsu.dmice.cmp.htn.model.Config;
import edu.ohsu.dmice.cmp.htn.registry.ConfigRegistry;

public class Program {
    public static void main(String[] args) {
        try {
            Config config = new Config("config.properties");
            ConfigRegistry.getInstance().setConfig(config);
            new TemplateBuilder().execute();
            System.out.println("\ndone");

        } catch (Exception e) {
            System.out.println("caught " + e.getClass().getName() + " - " + e.getMessage());
            e.printStackTrace();
        }
    }
}
