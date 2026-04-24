import mongoose from "mongoose"
import {DB_NAME} from "../constants.js"

const connectDB = async ()=> {
    try {
        const connectionInstance = await mongoose.connect(`${process.env.MONGODB_URI}/${DB_NAME}`)
        console.log("DB connected... Host is ",connectionInstance.connection.host);        
    } catch (error) {
        console.log("DB connection failed. Error is ", error);
        process.exit(1)  
    }
}

export default connectDB 
